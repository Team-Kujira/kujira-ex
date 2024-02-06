defmodule Kujira.Usk do
  @moduledoc """
  Kujira's lending platform.

  It has a vault-market architecture, where multiple Market can draw down from a single Vault. A Market must be whitelisted,
  as the repayment is guaranteed by its own execution logic, e.g. being over-collateralised and having a connection to Orca
  to liquidate collateral when needed
  """

  use Memoize
  alias GRPC.Channel
  alias Kujira.Contract
  alias Kujira.Usk.Market
  alias Kujira.Usk.Position
  alias Kujira.Usk.Controller

  @controller_code_id :kujira
                      |> Application.get_env(__MODULE__, controller_code_id: 11)
                      |> Keyword.get(:controller_code_id)

  @market_code_ids :kujira
                   |> Application.get_env(__MODULE__, market_code_ids: [136, 186])
                   |> Keyword.get(:market_code_ids)

  @doc """
  Fetches the Market contract and its current config from the chain.

  Config is very very rarely changed, if ever, and so this function is Memoized by default.
  Clear with `Memoize.invalidate(Kujira.Usk, :get_market, [address])`
  """

  @spec get_market(Channel.t(), String.t()) :: {:ok, Market.t()} | {:error, :not_found}
  def get_market(channel, address), do: Contract.get(channel, {Market, address})

  @doc """
  Fetches all Markets. This will only change when config changes or new Markets are added.
  It's Memoized, clearing every 24h.

  Manually clear with `Memoize.invalidate(Kujira.Usk, :list_markets)`
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
  Loads a Position by borrower address
  """

  @spec load_position(Channel.t(), Market.t(), String.t()) :: {:ok, Position.t()} | :error
  def load_position(channel, market, borrower) do
    with {:ok, res} <-
           Contract.query_state_smart(channel, market.address, %{
             position: %{holder: borrower}
           }),
         {:ok, position} <- Position.from_query(market, res) do
      {:ok, position}
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

    with {:ok, models} <- Contract.query_state_all(channel, market.address, 10 * 60 * 1000) do
      health =
        models
        |> Map.values()
        |> Enum.reduce(
          %{},
          fn model, agg ->
            with %{
                   #  "holder" => holder,
                   "deposit_amount" => deposit_amount,
                   "mint_amount" => mint_amount
                 } <- model,
                 {debt_amount, ""} <- Integer.parse(mint_amount),
                 {collateral_amount, ""} when collateral_amount > 0 <-
                   Integer.parse(deposit_amount) do
              liquidation_price =
                debt_amount
                |> Decimal.new()
                # TODO: Load current and historic interest rates. Calculate accrued interest
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

  @doc """
  Fetches the Controller contract and its current config from the chain.

  Config is very very rarely changed, if ever, and so this function is Memoized by default.
  Clear with `Memoize.invalidate(Kujira.Usk, :get_conroller, [address])`
  """

  @spec get_controller(Channel.t()) :: {:ok, Controller.t()} | {:error, :not_found}
  def get_controller(channel) do
    with {:ok, [contract]} <- Contract.by_code(channel, @controller_code_id),
         {:ok, res} <-
           Contract.query_state_smart(channel, contract, %{status: %{}}),
         {:ok, controller} <- Controller.from_query(contract, res) do
      {:ok, controller}
    else
      _ ->
        :error
    end
  end

  @doc """
  Creates a lazy stream for fetching all positions for a Market
  """
  @spec stream_positions(GRPC.Channel.t(), Market.t()) ::
          %Stream{}
  def stream_positions(channel, market) do
    Contract.stream_state_all(channel, market.address)
    |> Stream.map(fn x ->
      case Position.from_query(market, x) do
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
