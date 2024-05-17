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
  alias Kujira.Token
  alias Kujira.Contract
  import Cosmos.Bank.V1beta1.Query.Stub
  alias Cosmos.Bank.V1beta1.QuerySupplyOfRequest

  @pool_code_ids Application.compile_env(:kujira, __MODULE__,
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

  @leverage_code_ids Application.compile_env(:kujira, __MODULE__,
                       leverage_code_ids: [188, 290, 305, 317]
                     )
                     |> Keyword.get(:leverage_code_ids)

  @doc """
  Fetches the Pool contract and its current config from the chain
  """

  @spec get_pool(Channel.t(), String.t()) :: {:ok, Pool.t()} | {:error, :not_found}
  def get_pool(channel, address), do: Contract.get(channel, {Pool, address})

  @doc """
  Fetches all Pools
  """

  @spec list_pools(GRPC.Channel.t(), list(integer())) ::
          {:ok, list(Pool.t())} | {:error, GRPC.RPCError.t()}
  def list_pools(channel, code_ids \\ @pool_code_ids) when is_list(code_ids),
    do: Contract.list(channel, Pool, code_ids)

  @doc """
  Loads the current pool status onto the pool
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
      end
    )
  end

  @doc """
  Fetches the Leverage contract and its current config from the chain
  """

  @spec get_leverage(Channel.t(), String.t()) :: {:ok, Leverage.t()} | {:error, :not_found}
  def get_leverage(channel, address), do: Contract.get(channel, {Leverage, address})

  @doc """
  Fetches all Leverage markets
  """

  @spec list_leverage(GRPC.Channel.t(), list(integer())) ::
          {:ok, list(Leverage.t())} | {:error, GRPC.RPCError.t()}
  def list_leverage(channel, code_ids \\ @leverage_code_ids) when is_list(code_ids),
    do: Contract.list(channel, Leverage, code_ids)

  @doc """
  Loads the Leverage Market into a format that Orca can consume for health reporting. Default Memoization to 10 mins.

  This returns a {base, quote} tuple that represents the risk on both sides of liquidation

  The liquidation price of a position is dependent on the algorithm of the BOW pool.

  The liquidation price of a leveraged position on an XYK pool is defined as (loan_b - (max_ltv * size_b)) / ((max_ltv * size_a) - loan_a)

  This will demonstrate that the closer loan_b / loan_a is to size_b / size_a (and therefore the current price of the asset),
  the more extreme the price deviation required to reach max LTV. In some cases, eg when loan_b / loan_a == size_b / size_a, the value of the debt
  tracks the value of the collateral exactly, and as such the loan cannot be liquidated through price movement

  Finally, the at-risk collateral amount is determined as the net collateral amount required to be sold at the liquidation price
  E.g. a position with 1000 KUJI and 500 USDC collateral, 100 KUJI and 500 USDC debt, has a liquidation price of 0.1923
  At this price, we have ~ 1612 KUJI and 310 USDC as collateral. The USDC debt has a defecit of 190, which must be covered from the KUJI
  side of the collateral, so the at-risk collateral is 190 / 0.1923 ~= 988
  """
  @spec load_orca_markets(Channel.t(), Leverage.t(), integer() | nil) ::
          {:ok, {Kujira.Orca.Market.t(), Kujira.Orca.Market.t()}} | {:error, GRPC.RPCError.t()}
  def load_orca_markets(channel, market, precision \\ 3) do
    Decimal.Context.set(%Decimal.Context{rounding: :floor})
    base_denom = market.token_base.denom
    quote_denom = market.token_quote.denom

    with {:ok, pool} <- Contract.get(channel, market.bow),
         {:ok, %{status: %Status{} = pool_status}} <- load_pool(channel, pool),
         {:ok, models} <- Contract.query_state_all(channel, market.address),
         {:ok, vault_base} <- Contract.get(channel, market.ghost_vault_base),
         {:ok, %{status: %Ghost.Vault.Status{} = vault_base_status}} <-
           Ghost.load_vault(channel, vault_base),
         {:ok, vault_quote} <- Contract.get(channel, market.ghost_vault_quote),
         {:ok, %{status: %Ghost.Vault.Status{} = vault_quote_status}} <-
           Kujira.Ghost.load_vault(channel, vault_quote) do
      {health_base, health_quote} =
        models
        |> Map.values()
        |> Enum.reduce(
          {%{}, %{}},
          fn model, {health_base, health_quote} ->
            with %{
                   #  "holder" => holder,
                   "debt_shares" => [debt_shares_base, debt_shares_quote],
                   "lp_amount" => lp_amount
                 } <- model,
                 {debt_shares_base, ""} <- Decimal.parse(debt_shares_base),
                 {debt_shares_quote, ""} <- Decimal.parse(debt_shares_quote),
                 {lp_amount, ""} <- Decimal.parse(lp_amount) do
              case Leverage.liquidation_price(
                     market,
                     pool,
                     pool_status,
                     vault_base_status,
                     vault_quote_status,
                     lp_amount,
                     debt_shares_base,
                     debt_shares_quote
                   ) do
                {%Token{denom: ^base_denom}, price, amount} ->
                  {
                    Map.update(
                      health_base,
                      Decimal.round(price, precision),
                      amount,
                      &(&1 + amount)
                    ),
                    health_quote
                  }

                {%Token{denom: ^quote_denom}, price, amount} ->
                  {
                    health_base,
                    Map.update(
                      health_quote,
                      Decimal.round(price, precision),
                      amount,
                      &(&1 + amount)
                    )
                  }

                _ ->
                  {health_base, health_quote}
              end
            else
              _ -> {health_base, health_quote}
            end
          end
        )

      {:ok,
       {%Kujira.Orca.Market{
          address: {Leverage, market.address},
          queue: market.orca_queue_base,
          health: health_base
        },
        %Kujira.Orca.Market{
          address: {Leverage, market.address},
          queue: market.orca_queue_quote,
          health: health_quote
        }}}
    end
  end
end
