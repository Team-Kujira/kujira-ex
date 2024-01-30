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

  @vault_code_ids Application.get_env(:kujira, __MODULE__, vault_code_ids: [140])
                  |> Keyword.get(:vault_code_ids)

  @market_code_ids Application.get_env(:kujira, __MODULE__, market_code_ids: [136, 186])
                   |> Keyword.get(:market_code_ids)

  @doc """
  Fetches the Market contract and its current config from the chain.

  Config is very very rarely changed, if ever, and so this function is Memoized by default.
  Clear with `Memoize.invalidate(Kujira.Ghost, :get_market, [address])`
  """

  @spec get_market(Channel.t(), String.t()) :: {:ok, Market.t()} | {:error, :not_found}
  def get_market(channel, address), do: Contract.get(channel, {Market, address})

  @doc """
  Fetches all Markets. This will only change when config changes or new Markets are added.
  It's Memoized, clearing every 24h.

  Manually clear with `Memoize.invalidate(Kujira.Ghost, :list_markets)`
  """

  @spec list_markets(GRPC.Channel.t(), list(integer())) :: {:ok, list(Market.t())} | :error
  def list_markets(channel, code_ids \\ @market_code_ids) when is_list(code_ids),
    do: Contract.list(channel, Market, code_ids)

  @doc """
  Loads the current Status into the Market
  """

  @spec load_market(Channel.t(), Market.t()) :: {:ok, Market.t()} | :error
  def load_market(channel, market) do
    with {:ok, res} <-
           Contract.query_state_smart(channel, market.address, %{status: %{}}),
         {:ok, status} <- Market.Status.from_query(res) do
      {:ok, %{market | status: status}}
    else
      _ ->
        :error
    end
  end

  @doc """
  Loads the Market into a format that Orca can consume for health reporting.
  It's Memoized due to the call to `Contract.query_state_all`, clearing every 10m.

  Manually clear with `Memoize.invalidate(Kujira.Contract, :query_state_all, [market.address])`
  """
  @spec load_orca_market(Channel.t(), Market.t(), integer() | nil) ::
          {:ok, Kujira.Orca.Market.t()} | :error
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
  Clear with `Memoize.invalidate(Kujira.Ghost, :get_vault, [address])`
  """

  @spec get_vault(Channel.t(), String.t()) :: {:ok, Vault.t()} | {:error, :not_found}
  def get_vault(channel, address), do: Contract.get(channel, {Vault, address})

  @doc """
  Loads the current Status into the Vault
  """

  @spec load_vault(Channel.t(), Vault.t()) :: {:ok, Vault.t()} | :error
  def load_vault(channel, vault) do
    with {:ok, res} <-
           Contract.query_state_smart(channel, vault.address, %{status: %{}}),
         {:ok, status} <- Vault.Status.from_query(res) do
      {:ok, %{vault | status: status}}
    else
      _ ->
        :error
    end
  end

  @doc """
  Fetches all Vaults. This will only change when config changes or new Vaults are added.
  It's Memoized, clearing every 24h.

  Manually clear with `Memoize.invalidate(Kujira.Ghost, :list_vaults)`
  """

  @spec list_vaults(GRPC.Channel.t(), list(integer())) :: {:ok, list(Vault.t())} | :error
  def list_vaults(channel, code_ids \\ @vault_code_ids) when is_list(code_ids),
    do: Contract.list(channel, Vault, code_ids)

  @doc """
  Creates a lazy stream for fetching all positions for a Market
  """
  @spec stream_positions(GRPC.Channel.t(), Market.t(), Vault.t()) ::
          %Stream{}
  def stream_positions(channel, market, vault) do
    Contract.stream_state_all(channel, market.address)
    |> Stream.map(fn
      %{"collateral_amount" => _, "debt_shares" => _, "holder" => _} = position ->
        Position.from_query(market, vault, position)

      _ ->
        nil
    end)
    |> Stream.filter(fn
      nil -> false
      _ -> true
    end)
  end
end
