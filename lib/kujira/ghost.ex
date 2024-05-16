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
  """

  @spec get_market(Channel.t(), String.t()) :: {:ok, Market.t()} | {:error, :not_found}
  def get_market(channel, address), do: Contract.get(channel, {Market, address})

  @doc """
  Fetches all Markets
  """

  @spec list_markets(GRPC.Channel.t(), list(integer())) ::
          {:ok, list(Market.t())} | {:error, GRPC.RPCError.t()}
  def list_markets(channel, code_ids \\ @market_code_ids) when is_list(code_ids),
    do: Contract.list(channel, Market, code_ids)

  @doc """
  Loads the current Status into the Market
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
      end
    )
  end

  @doc """
  Loads a Position by borrower address
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
      end
    )
  end

  @doc """
  Gets the total deposit value of an address in a Vault.
  Under the hood, this queries the addresses balance of the receipt token, and adjusts it by the deposit_ratio
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
      end
    )
  end

  def get_deposit(channel, %Vault{status: :not_loaded} = vault, borrower) do
    with {:ok, vault} <- load_vault(channel, vault) do
      get_deposit(channel, vault, borrower)
    end
  end

  @doc """
  Loads the Market into a format that Orca can consume for health reporting
  """
  @spec load_orca_market(Channel.t(), Market.t(), integer() | nil) ::
          {:ok, Kujira.Orca.Market.t()} | {:error, GRPC.RPCError.t()}
  def load_orca_market(channel, market, precision \\ 3) do
    Decimal.Context.set(%Decimal.Context{rounding: :floor})

    with {:ok, models} <- Contract.query_state_all(channel, market.address),
         {:ok, vault} <- Contract.get(channel, market.vault),
         {:ok, vault} <- load_vault(channel, vault) do
      # Liquidation prices are in terms of the base units. Precision should be adjusted for decimal delta
      precision =
        precision + market.collateral_token.meta.decimals - vault.deposit_token.meta.decimals

      health =
        models
        |> Map.values()
        |> Enum.reduce(
          %{},
          fn model, agg ->
            with {:ok, position} <- Position.from_query(market, vault, model) do
              liquidation_price =
                Position.liquidation_price(position, market, vault)
                |> Decimal.round(precision, :ceiling)

              Map.update(
                agg,
                liquidation_price,
                position.collateral_amount,
                &(&1 + position.collateral_amount)
              )
            else
              _ -> agg
            end
          end
        )

      {:ok,
       %Kujira.Orca.Market{
         address: {Market, market.address},
         queue: market.orca_queue,
         health: health
       }}
    end
  end

  def load_vault_oracle_price(channel, %Vault{oracle_denom: {:live, denom}}),
    do: Kujira.Oracle.load_price(channel, denom)

  def load_vault_oracle_price(_, %Vault{oracle_denom: {:static, value}}),
    do: {:ok, value}

  @doc """
  Fetches the Vault contract and its current config from the chain
  """

  @spec get_vault(Channel.t(), String.t()) :: {:ok, Vault.t()} | {:error, :not_found}
  def get_vault(channel, address), do: Contract.get(channel, {Vault, address})

  @doc """
  Loads the current Status into the Vault
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
      end
    )
  end

  @doc """
  Fetches all Vaults
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
end
