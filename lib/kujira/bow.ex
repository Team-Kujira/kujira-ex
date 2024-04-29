defmodule Kujira.Bow do
  @moduledoc """
  Kujira's on-chain Market Maker for FIN.
  """

  alias Kujira.Bow.Leverage
  alias Kujira.Bow.Pool
  alias Kujira.Bow.Pool.Lsd
  alias Kujira.Bow.Pool.Stable
  alias Kujira.Bow.Pool.Xyk
  alias Kujira.Bow.Status
  alias Kujira.Ghost
  alias Kujira.Contract
  import Cosmos.Bank.V1beta1.Query.Stub
  alias Cosmos.Bank.V1beta1.QuerySupplyOfRequest

  @pool_code_ids Application.get_env(:kujira, __MODULE__,
                   pool_code_ids: [
                     54,
                     126,
                     294,
                     # LSD Strategy
                     158,
                     167,
                     # Stable Strategy
                     161,
                     166
                   ]
                 )
                 |> Keyword.get(:pool_code_ids)

  @leverage_code_ids Application.get_env(:kujira, __MODULE__, leverage_code_ids: [188, 290])
                     |> Keyword.get(:leverage_code_ids)

  @doc """
  Fetches the Pool contract and its current config from the chain.

  Config is very very rarely changed, if ever, and so this function is Memoized by default.

  Manually clear with `Kujira.Bow.invalidate(:get_pool, address)`
  """

  @spec get_pool(Channel.t(), String.t()) :: {:ok, Pool.t()} | {:error, :not_found}
  def get_pool(channel, address), do: Contract.get(channel, {Pool, address})

  @doc """
  Fetches all Pools. This will only change when config changes or new Pools are added.
  It's Memoized, clearing every 24h.

  Manually clear with `Kujira.Bow.invalidate(:list_pools)`
  """

  @spec list_pools(GRPC.Channel.t(), list(integer())) ::
          {:ok, list(Pool.t())} | {:error, GRPC.RPCError.t()}
  def list_pools(channel, code_ids \\ @pool_code_ids) when is_list(code_ids),
    do: Contract.list(channel, Pool, code_ids)

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
  **WIP**

  Loads the Leverage Market into a format that Orca can consume for health reporting. Default Memoization to 10 mins

  The liquidation price of a position is dependent on the algorithm of the BOW pool.

  Eg: KUJI is at 2 USDC when a position is opened. The BOW pool is in a 1:2 ratio, and I deposit 100 KUJI and borrow 200 USDC.
  My initial LTV is 0.5 - a total of $400 of LP tokens with $200 borrowed.
  Say the max LTV is 0.8, then liquidation can ocurr when the LP value decreases to 250 USDC.
  In this instance, as the ratio of the pool should be the current price, there will be 125 USDC and X * 125 = 20000 so 160 KUJI where the price is now 0.78125

  The liquidation price if KUJI is the borrowed asset is the same deviation in the opposite direction
  I deposit 200 USDC and borrow 100 KUJI
  Max LTV 0.8 liquidation can ocurr when LP value is 125 KUJI
  So there'll be 62.5 KUJI and 62.5 * Y = 20000 so 320 USDC and the price is 5.12

  Blended liquidation price
  I deposit 100 USDC, 75 KUJI and borrow 100 USDC and 25 KUJI
  Max LTV 0.8 liquidation can ocurr when LP value is 125 KUJI
  So there'll be 62.5 KUJI and 62.5 * Y = 20000 so 320 USDC and the price is 5.12




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
      # IO.inspect(pool)
      # IO.inspect(vault_base)
      # IO.inspect(vault_quote)

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
              # IO.inspect({debt_amount_base, debt_amount_quote, lp_amount})
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
