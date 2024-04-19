defmodule Kujira.Ghost do
  @moduledoc """
  Kujira's lending platform.

  It has a vault-market architecture, where multiple Market can draw down from a single Vault. A Market must be whitelisted,
  as the repayment is guaranteed by its own execution logic, e.g. being over-collateralised and having a connection to Orca
  to liquidate collateral when needed
  """

  use Memoize
  alias GRPC.Channel
  alias Kujira.Contract
  alias Kujira.Ghost.Market
  alias Kujira.Ghost.Position
  alias Kujira.Ghost.Vault
  alias Cosmos.Bank.V1beta1.Query.Stub, as: BankQuery
  alias Cosmos.Bank.V1beta1.QueryBalanceRequest
  alias Cosmos.Bank.V1beta1.QueryBalanceResponse

  @vault_code_ids Application.get_env(:kujira, __MODULE__, vault_code_ids: [140])
                  |> Keyword.get(:vault_code_ids)

  @market_code_ids Application.get_env(:kujira, __MODULE__, market_code_ids: [291])
                   |> Keyword.get(:market_code_ids)

  @doc """
  Fetches the Market contract and its current config from the chain.

  Config is very very rarely changed, if ever, and so this function is Memoized by default.
  Manually clear with `Kujira.Ghost.invalidate(:get_market, address)`
  """

  @spec get_market(Channel.t(), String.t()) :: {:ok, Market.t()} | {:error, :not_found}
  def get_market(channel, address), do: Contract.get(channel, {Market, address})

  @doc """
  Fetches all Markets. This will only change when config changes or new Markets are added.
  It's Memoized, clearing every 24h.

  Manually clear with `Kujira.Ghost.invalidate(:list_markets)`
  """

  @spec list_markets(GRPC.Channel.t(), list(integer())) ::
          {:ok, list(Market.t())} | {:error, GRPC.RPCError.t()}
  def list_markets(channel, code_ids \\ @market_code_ids) when is_list(code_ids),
    do: Contract.list(channel, Market, code_ids)

  @doc """
  Loads the current Status into the Market. Default Memoization to ~ block time / 2 = 2s

  Manually clear with `Kujira.Ghost.invalidate(:load_market, market)`
  """

  @spec load_market(Channel.t(), Market.t()) :: {:ok, Market.t()} | {:error, GRPC.RPCError.t()}
  def load_market(channel, market) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :load_market, [market]},
      fn ->
        with {:ok, res} <-
               Contract.query_state_smart(channel, market.address, %{status: %{}}),
             {:ok, status} <- Market.Status.from_query(res) do
          {:ok, %{market | status: status}}
        else
          err -> err
        end
      end,
      expires_in: 2000
    )
  end

  @doc """
  Loads a Position by borrower address. Default Memoization to ~ block time / 2 = 2s

  Manually clear with `Kujira.Ghost.invalidate(:load_position, market, borrower)`
  """

  @spec load_position(Channel.t(), Market.t(), String.t()) ::
          {:ok, Position.t()} | {:error, GRPC.RPCError.t()}
  def load_position(channel, market, borrower) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :load_position, [market, borrower]},
      fn ->
        with {:ok, res} <-
               Contract.query_state_smart(channel, market.address, %{
                 position: %{holder: borrower}
               }),
             {:ok, vault} <- Contract.get(channel, market.vault),
             {:ok, vault} <- load_vault(channel, vault),
             {:ok, position} <- Position.from_query(market, vault, res) do
          {:ok, position}
        else
          err -> err
        end
      end,
      expires_in: 2000
    )
  end

  @doc """
  Gets the total deposit value of an address in a Vault.
  Under the hood, this queries the addresses balance of the receipt token, and adjusts it by the deposit_ratio

  Manually clear with `Kujira.Ghost.invalidate(:get_deposit, vault, depositor)`
  """

  @spec get_deposit(Channel.t(), Vault.t(), String.t()) ::
          {:ok, integer()} | {:error, GRPC.RPCError.t()}
  def get_deposit(
        channel,
        %Vault{receipt_token: receipt_token, status: %Vault.Status{deposit_ratio: deposit_ratio}} =
          vault,
        borrower
      ) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :get_deposit, [vault, borrower]},
      fn ->
        with {:ok, %QueryBalanceResponse{balance: %{amount: amount}}} <-
               BankQuery.balance(
                 channel,
                 QueryBalanceRequest.new(address: borrower, denom: receipt_token.denom)
               ),
             {amount, ""} <- Decimal.parse(amount) do
          {:ok, Decimal.mult(amount, deposit_ratio) |> Decimal.to_integer()}
        else
          err -> err
        end
      end,
      expires_in: 2000
    )
  end

  def get_deposit(channel, %Vault{status: :not_loaded} = vault, borrower) do
    with {:ok, vault} <- load_vault(channel, vault) do
      get_deposit(channel, vault, borrower)
    end
  end

  @doc """
  Loads the Market into a format that Orca can consume for health reporting. Default Memoization to 10 mins

  Manually clear with `Kujira.Ghost.invalidate(:load_orca_market, market)`
  """
  @spec load_orca_market(Channel.t(), Market.t(), integer() | nil) ::
          {:ok, Kujira.Orca.Market.t()} | {:error, GRPC.RPCError.t()}
  def load_orca_market(channel, market, precision \\ 3) do
    Decimal.Context.set(%Decimal.Context{rounding: :floor})

    with {:ok, models} <- Contract.query_state_all(channel, market.address, 10 * 60 * 1000),
         {:ok, vault} <- Contract.get(channel, market.vault),
         {:ok, vault} <- load_vault(channel, vault) do
      health =
        models
        |> Map.values()
        |> Enum.reduce(
          %{},
          fn model, agg ->
            with %{
                   #  "holder" => holder,
                   "collateral_amount" => collateral_amount,
                   "debt_shares" => debt_shares
                 } <- model,
                 {debt_shares, ""} <- Integer.parse(debt_shares),
                 {collateral_amount, ""} when collateral_amount > 0 <-
                   Integer.parse(collateral_amount) do
              liquidation_price =
                debt_shares
                |> Decimal.new()
                |> Decimal.mult(vault.status.debt_ratio)
                |> Decimal.div(collateral_amount |> Decimal.new() |> Decimal.mult(market.max_ltv))
                |> Decimal.round(precision, :ceiling)

              Map.update(agg, liquidation_price, collateral_amount, &(&1 + collateral_amount))
            else
              _ -> agg
            end
          end
        )

      {:ok, %Kujira.Orca.Market{address: market.address, health: health}}
    end
  end

  def load_vault_oracle_price(channel, %Vault{oracle_denom: {:live, denom}}),
    do: Kujira.Oracle.load_price(channel, denom)

  def load_vault_oracle_price(_, %Vault{oracle_denom: {:static, value}}),
    do: {:ok, value}

  @doc """
  Fetches the Vault contract and its current config from the chain.

  Config is very very rarely changed, if ever, and so this function is Memoized by default.
  Manually clear with `Kujira.Ghost.invalidate(:get_vault, address)`
  """

  @spec get_vault(Channel.t(), String.t()) :: {:ok, Vault.t()} | {:error, :not_found}
  def get_vault(channel, address), do: Contract.get(channel, {Vault, address})

  @doc """
  Loads the current Status into the Vault. Default Memoization to ~ block time / 2 = 2s

  Manually clear with `Kujira.Ghost.invalidate(:load_vault, vault)`
  """

  @spec load_vault(Channel.t(), Vault.t()) :: {:ok, Vault.t()} | {:error, GRPC.RPCError.t()}
  def load_vault(channel, vault) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :load_vault, [vault]},
      fn ->
        with {:ok, res} <-
               Contract.query_state_smart(channel, vault.address, %{status: %{}}),
             {:ok, status} <- Vault.Status.from_query(res) do
          {:ok, %{vault | status: status}}
        else
          err -> err
        end
      end,
      expires_in: 2000
    )
  end

  @doc """
  Fetches all Vaults. This will only change when config changes or new Vaults are added.
  It's Memoized, clearing every 24h.

  Manually clear with `Kujira.Ghost.invalidate(:list_vaults)`
  """

  @spec list_vaults(GRPC.Channel.t(), list(integer())) ::
          {:ok, list(Vault.t())} | {:error, GRPC.RPCError.t()}
  def list_vaults(channel, code_ids \\ @vault_code_ids) when is_list(code_ids),
    do: Contract.list(channel, Vault, code_ids)

  @doc """
  Creates a lazy stream for fetching all positions for a Market
  """
  @spec stream_positions(GRPC.Channel.t(), Market.t(), Vault.t()) ::
          %Stream{}
  def stream_positions(channel, market, vault) do
    Contract.stream_state_all(channel, market.address)
    |> Stream.map(fn x ->
      case Position.from_query(market, vault, x) do
        {:ok, position} -> position
        _ -> nil
      end
    end)
    |> Stream.filter(fn
      nil -> false
      _ -> true
    end)
  end

  def invalidate(:list_vaults),
    do: Memoize.invalidate(Kujira.Contract, :list, [Vault, @vault_code_ids])

  def invalidate(:list_markets),
    do: Memoize.invalidate(Kujira.Contract, :list, [Market, @market_code_ids])

  def invalidate(:get_vault, address),
    do: Memoize.invalidate(Kujira.Contract, :get, [{Vault, address}])

  def invalidate(:get_market, address),
    do: Memoize.invalidate(Kujira.Contract, :get, [{Market, address}])

  def invalidate(:list_vaults, code_ids),
    do: Memoize.invalidate(Kujira.Contract, :list, [Vault, code_ids])

  def invalidate(:list_markets, code_ids),
    do: Memoize.invalidate(Kujira.Contract, :list, [Market, code_ids])

  def invalidate(:load_vault, vault),
    do: Memoize.invalidate(__MODULE__, :load_vault, [vault, 100])

  def invalidate(:load_market, market),
    do: Memoize.invalidate(__MODULE__, :load_market, [market, 100])

  def invalidate(:load_orca_market, market),
    do: Memoize.invalidate(Kujira.Contract, :query_state_all, [market.address])

  def invalidate(:load_vault, vault, limit),
    do: Memoize.invalidate(__MODULE__, :load_vault, [vault, limit])

  def invalidate(:load_market, market, limit),
    do: Memoize.invalidate(__MODULE__, :load_market, [market, limit])

  def invalidate(:load_position, market, position),
    do: Memoize.invalidate(__MODULE__, :load_position, [market, position])

  def invalidate(:get_deposit, vault, depositor),
    do: Memoize.invalidate(__MODULE__, :get_deposit, [vault, depositor])
end
