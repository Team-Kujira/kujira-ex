defmodule Kujira.Usk do
  @moduledoc """
  Kujira's decentralized stablecoin

  Users deposit collateral and mint USK up to the maximum LTV permitted by the individual market
  """

  use Memoize
  alias GRPC.Channel
  alias Kujira.Contract
  alias Kujira.Usk.Market
  alias Kujira.Usk.Margin
  alias Kujira.Usk.Position
  alias Kujira.Usk.Controller

  @controller_code_id :kujira
                      |> Application.get_env(__MODULE__, controller_code_id: 11)
                      |> Keyword.get(:controller_code_id)

  @market_code_ids :kujira
                   |> Application.get_env(__MODULE__, market_code_ids: [136, 186])
                   |> Keyword.get(:market_code_ids)

  @margin_code_ids :kujira
                   |> Application.get_env(__MODULE__, margin_code_ids: [87])
                   |> Keyword.get(:margin_code_ids)

  @doc """
  Fetches the Market contract and its current config from the chain.

  Config is very very rarely changed, if ever, and so this function is Memoized by default.
  Manually clear with `Memoize.invalidate(Kujira.Contract, :get, [{Market, address}])`
  """

  @spec get_market(Channel.t(), String.t()) :: {:ok, Market.t()} | {:error, :not_found}
  def get_market(channel, address), do: Contract.get(channel, {Market, address})

  @doc """
  Fetches all Markets. This will only change when config changes or new Markets are added.
  It's Memoized, clearing every 24h.

  Manually clear with `Memoize.invalidate(Kujira.Contract, :list, [Market, code_ids])`
  """

  @spec list_markets(GRPC.Channel.t(), list(integer())) :: {:ok, list(Market.t())} | :error
  def list_markets(channel, code_ids \\ @market_code_ids) when is_list(code_ids),
    do: Contract.list(channel, Market, code_ids)

  @doc """
  Loads the current Status into the Market. efault Memoization to ~ block time / 2 = 2s

  Manually clear with `Kujira.Usk.invalidate(:load_market, address)`
  """

  @spec load_market(Channel.t(), Market.t()) :: {:ok, Market.t()} | :error
  def load_market(channel, market) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :load_market, [market]},
      fn ->
        with {:ok, res} <-
               Contract.query_state_smart(channel, market.address, %{status: %{}}),
             {:ok, status} <- Market.Status.from_query(res) do
          {:ok, %{market | status: status}}
        else
          _ ->
            :error
        end
      end,
      expires_in: 2000
    )
  end

  @doc """
  Fetches the Margin contract and its current config from the chain.

  Config is very very rarely changed, if ever, and so this function is Memoized by default.

  Manually clear with `Kujira.Usk.invalidate(:get_margin, address)`
  """

  @spec get_margin(Channel.t(), String.t()) :: {:ok, Margin.t()} | {:error, :not_found}
  def get_margin(channel, address), do: Contract.get(channel, {Margin, address})

  @doc """
  Fetches all Margins. This will only change when config changes or new Margins are added.
  It's Memoized, clearing every 24h.

  Manually clear with `Kujira.Usk.invalidate(:list_margins)`
  """

  @spec list_margins(GRPC.Channel.t(), list(integer())) :: {:ok, list(Margin.t())} | :error
  def list_margins(channel, code_ids \\ @margin_code_ids) when is_list(code_ids),
    do: Contract.list(channel, Margin, code_ids)

  @doc """
  Loads the current Status into the Margin.market. Default Memoization to ~ block time / 2 = 2s

  Manually clear with `Kujira.Usk.invalidate(:load_margin, margin)`
  """
  @spec load_margin(Channel.t(), Margin.t()) :: {:ok, Margin.t()} | :error
  def load_margin(channel, margin) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :load_margin, [margin]},
      fn ->
        with {:ok, res} <-
               Contract.query_state_smart(channel, margin.address, %{status: %{}}),
             {:ok, status} <- Market.Status.from_query(res) do
          {:ok, %{margin | market: %{margin.market | status: status}}}
        else
          _ ->
            :error
        end
      end,
      expires_in: 2000
    )
  end

  @doc """
  Loads a Position by borrower address. Default Memoization to ~ block time / 2 = 2s

  Manually clear with `Kujira.Usk.invalidate(:load_position, market, borrower)`
  """

  @spec load_position(Channel.t(), Market.t(), String.t()) :: {:ok, Position.t()} | :error
  def load_position(channel, market, borrower) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :load_position, [market, borrower]},
      fn ->
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
      end,
      expires_in: 2000
    )
  end

  @doc """
  Loads the Market into a format that Orca can consume for health reporting. Default Memoization to 10 mins

  Can be used for both a Ghost.Market and Ghost.Margin.market, as they both use the same underlying
  state schema

  Manually clear with `Kujira.Usk.invalidate(:load_orca_market, market)`
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

  Manually clear with `Kujira.Usk.invalidate(:get_controller)`
  """

  @spec get_controller(Channel.t()) :: {:ok, Controller.t()} | {:error, :not_found}
  def get_controller(channel) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :get_controller, []},
      fn ->
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
    )
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

  def invalidate(:get_controller),
    do: Memoize.invalidate(Kujira.Contract, :list, [Margin, @margin_code_ids])

  def invalidate(:list_margins),
    do: Memoize.invalidate(Kujira.Contract, :list, [Margin, @margin_code_ids])

  def invalidate(:list_markets),
    do: Memoize.invalidate(Kujira.Contract, :list, [Market, @market_code_ids])

  def invalidate(:get_margin, address),
    do: Memoize.invalidate(Kujira.Contract, :get, [{Margin, address}])

  def invalidate(:get_market, address),
    do: Memoize.invalidate(Kujira.Contract, :get, [{Market, address}])

  def invalidate(:list_margins, code_ids),
    do: Memoize.invalidate(Kujira.Contract, :list, [Margin, code_ids])

  def invalidate(:list_markets, code_ids),
    do: Memoize.invalidate(Kujira.Contract, :list, [Market, code_ids])

  def invalidate(:load_margin, margin),
    do: Memoize.invalidate(__MODULE__, :load_margin, [margin, 100])

  def invalidate(:load_market, market),
    do: Memoize.invalidate(__MODULE__, :load_market, [market, 100])

  def invalidate(:load_orca_market, market),
    do: Memoize.invalidate(Kujira.Contract, :query_state_all, [market.address])

  def invalidate(:load_margin, margin, limit),
    do: Memoize.invalidate(__MODULE__, :load_margin, [margin, limit])

  def invalidate(:load_market, market, limit),
    do: Memoize.invalidate(__MODULE__, :load_market, [market, limit])

  def invalidate(:load_position, market, position),
    do: Memoize.invalidate(__MODULE__, :load_position, [market, position])
end
