defmodule Kujira.Bow do
  @moduledoc """
  Kujira's on-chain Market Maker for FIN.
  """

  alias Kujira.Bow.Leverage
  alias Kujira.Bow.Lsd
  alias Kujira.Bow.Stable
  alias Kujira.Bow.Status
  alias Kujira.Bow.Xyk
  alias Kujira.Ghost
  alias Kujira.Contract
  import Cosmos.Bank.V1beta1.Query.Stub
  alias Cosmos.Bank.V1beta1.QuerySupplyOfRequest

  @leverage_code_ids Application.get_env(:kujira, __MODULE__, leverage_code_ids: [188])
                     |> Keyword.get(:leverage_code_ids)

  @doc """
  Fetches an XYK algorithm pool and its current config from the chain.

  Config is very very rarely changed, if ever, and so this function is Memoized by default.

  Manually clear with `Kujira.Bow.invalidate(:get_pool_xyk, address)`
  """

  @spec get_pool_xyk(Channel.t(), String.t()) :: {:ok, Leverage.t()} | {:error, :not_found}
  def get_pool_xyk(channel, address), do: Contract.get(channel, {Xyk, address})

  @doc """
  Loads the current pool status onto the pool

  It's Memoized, clearing every 2 seconds.

  Manually clear with `Kujira.Bow.invalidate(:load_pool, address)`
  """

  @spec load_pool(Channel.t(), Xyk.t()) :: {:ok, Xyk.t()} | {:error, :not_found}
  @spec load_pool(Channel.t(), Stable.t()) :: {:ok, Stable.t()} | {:error, :not_found}
  @spec load_pool(Channel.t(), Lsd.t()) :: {:ok, Lsd.t()} | {:error, :not_found}
  def load_pool(channel, pool) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :load_pool, [pool]},
      fn ->
        with {:ok, status} <-
               Contract.query_state_smart(channel, pool.address, %{pool: %{}}),
             {:ok, supply} <-
               supply_of(channel, QuerySupplyOfRequest.new(denom: pool.token_lp.denom)) do
          {:ok, %{pool | status: Status.from_query(status, supply)}}
        else
          err -> err
        end
      end,
      expires_in: 2000
    )
  end

  @doc """
  Fetches the Leverage contract and its current config from the chain.

  Config is very very rarely changed, if ever, and so this function is Memoized by default.

  Manually clear with `Kujira.Bow.invalidate(:get_leverage, address)`
  """

  @spec get_leverage(Channel.t(), String.t()) :: {:ok, Leverage.t()} | {:error, :not_found}
  def get_leverage(channel, address), do: Contract.get(channel, {Leverage, address})

  @doc """
  Fetches all Leverage markets. This will only change when config changes or new markets are added.
  It's Memoized, clearing every 24h.

  Manually clear with `Kujira.Bow.invalidate(:list_leverage)`
  """

  @spec list_leverage(GRPC.Channel.t(), list(integer())) ::
          {:ok, list(Leverage.t())} | {:error, GRPC.RPCError.t()}
  def list_leverage(channel, code_ids \\ @leverage_code_ids) when is_list(code_ids),
    do: Contract.list(channel, Leverage, code_ids)

  @doc """
  Loads the Leverage Market into a format that Orca can consume for health reporting. Default Memoization to 10 mins

  Manually clear with `Kujira.Bow.invalidate(:load_orca_market, market)`
  """
  @spec load_orca_market(Channel.t(), Leverage.t(), integer() | nil) ::
          {:ok, Kujira.Orca.Market.t()} | {:error, GRPC.RPCError.t()}
  def load_orca_market(channel, market, precision \\ 3) do
    Decimal.Context.set(%Decimal.Context{rounding: :floor})

    with {:ok, pool} <- Contract.get(channel, market.bow),
         {:ok, %{status: %Status{} = pool_status}} <- load_pool(channel, pool),
         {:ok, models} <- Contract.query_state_all(channel, market.address, 10 * 60 * 1000),
         {:ok, vault_base} <- Contract.get(channel, market.ghost_vault_base),
         {:ok, %{status: %Ghost.Vault.Status{} = vault_base_status}} <-
           Ghost.load_vault(channel, vault_base),
         {:ok, vault_quote} <- Contract.get(channel, market.ghost_vault_quote),
         {:ok, %{status: %Ghost.Vault.Status{} = vault_quote_status}} <-
           Kujira.Ghost.load_vault(channel, vault_quote) do
      IO.inspect(pool)
      IO.inspect(vault_base)
      IO.inspect(vault_quote)

      health =
        models
        |> Map.values()
        |> Enum.reduce(
          %{},
          fn model, agg ->
            with %{
                   # "idx" => idx,
                   #  "holder" => holder,
                   "debt_shares" => [debt_shares_base, debt_shares_quote],
                   "lp_amount" => lp_amount
                 } <- model,
                 {debt_shares_base, ""} <- Decimal.parse(debt_shares_base),
                 {debt_shares_quote, ""} <- Decimal.parse(debt_shares_quote),
                 {lp_amount, ""} <- Decimal.parse(lp_amount) do
              debt_amount_base = Decimal.mult(debt_shares_base, vault_base_status.debt_ratio)
              debt_amount_quote = Decimal.mult(debt_shares_quote, vault_quote_status.debt_ratio)
              IO.inspect({debt_amount_base, debt_amount_quote, lp_amount})

              # Map.update(agg, liquidation_price, collateral_amount, &(&1 + collateral_amount))
              agg
            else
              _ -> agg
            end
          end
        )

      {:ok, %Kujira.Orca.Market{address: market.address, health: health}}
    end
  end
end
