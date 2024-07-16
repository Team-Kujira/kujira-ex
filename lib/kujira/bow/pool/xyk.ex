defmodule Kujira.Bow.Pool.Xyk do
  @moduledoc """
  A instance of the BOW XYK Market Making strategy.

  ## Fields
  * `:address` - The address of the contract

  * `:owner` - The owner of the contract

  * `:fin_pair` - The FIN Pair that this pool market-makes for

  * `:token_lp` - The receipt token minted when deposits are made to the pool

  * `:token_base` - The base token of the FIN Pair

  * `:token_quote` - The quote token of the FIN Pair

  * `:decimal_delta` - Base decimals - Quote decimals. Used to assert correct price_precision

  * `:price_precision` - Maximum number of decimal places of the human price when submitting orders

  * `:intervals` - The space between orders placed by the contract

  * `:fee` - The premium calculated on top of the XY=K algorithm, used to size orders

  * `:status` - The current deposit status
  """

  alias Kujira.Fin
  alias Kujira.Token
  alias Kujira.Bow.Status

  defstruct [
    :address,
    :owner,
    :fin_pair,
    :token_lp,
    :token_base,
    :token_quote,
    :decimal_delta,
    :price_precision,
    :intervals,
    :fee,
    :status
  ]

  @type t :: %__MODULE__{
          address: String.t(),
          owner: String.t(),
          fin_pair: {Fin.Pair, String.t()},
          token_lp: Token.t(),
          token_base: Token.t(),
          token_quote: Token.t(),
          decimal_delta: integer(),
          price_precision: integer(),
          intervals: [Decimal.t()],
          fee: Decimal.t(),
          status: Status.t()
        }

  @spec from_config(GRPC.Channel.t(), String.t(), map()) ::
          {:error, GRPC.RPCError.t()} | {:error, :invalid_config} | {:ok, __MODULE__.t()}
  def from_config(channel, address, %{
        "owner" => owner,
        "denoms" => [
          denom_base,
          denom_quote
        ],
        "price_precision" => %{
          "decimal_places" => price_precision
        },
        "decimal_delta" => decimal_delta,
        "fin_contract" => fin_pair,
        "intervals" => intervals,
        "fee" => fee
      }) do
    with {fee, ""} <- Decimal.parse(fee),
         {:ok, token_base} <- Token.from_denom(channel, denom_base),
         {:ok, token_quote} <- Token.from_denom(channel, denom_quote),
         {:ok, token_lp} <- Token.from_denom(channel, "factory/#{address}/ulp") do
      {:ok,
       %__MODULE__{
         address: address,
         owner: owner,
         fin_pair: {Fin.Pair, fin_pair},
         token_lp: token_lp,
         token_base: token_base,
         token_quote: token_quote,
         decimal_delta: decimal_delta,
         price_precision: price_precision,
         intervals:
           Enum.reduce(intervals, [], fn x, agg ->
             case Decimal.parse(x) do
               {i, ""} -> [i | agg]
               _ -> agg
             end
           end),
         fee: fee,
         status: :not_loaded
       }}
    else
      # Comes from Decimal.parse
      :error ->
        {:error, :invalid_config}

      err ->
        err
    end
  end

  def from_config(_, _, _), do: {:error, :invalid_config}

  @doc """
  Returns the orders placed by the pool for a given set of intervals
  """
  @spec compute_orders(__MODULE__.t()) :: [{Decimal.t(), non_neg_integer()}]
  def compute_orders(%__MODULE__{intervals: intervals} = p) do
    {_, bids} =
      Enum.reduce(intervals, {p, []}, fn v, {x, y} ->
        {x, o} = compute_order(x, v, :bid)
        {x, [o | y]}
      end)

    {_, asks} =
      Enum.reduce(intervals, {p, []}, fn v, {x, y} ->
        {x, o} = compute_order(x, v, :bid)
        {x, [o | y]}
      end)

    Enum.concat(bids, asks)
  end

  @doc """
  Returns the next order placed by the pool for a given set of intervals
  """
  @spec compute_order(__MODULE__.t(), Decimal.t(), :bid | :ask) ::
          {__MODULE__.t(), {Decimal.t(), non_neg_integer()}}
  def compute_order(
        %__MODULE__{
          fee: fee,
          price_precision: price_precision,
          status: %Status{base_amount: base_amount, quote_amount: quote_amount} = s
        } = p,
        i,
        :bid
      ) do
    offer_amount = Decimal.mult(i, Decimal.new(quote_amount))

    {new_quote_amount, target_base_amount, fee_amount} =
      size_order(quote_amount, base_amount, offer_amount, fee)

    new_base_amount = Decimal.add(target_base_amount, fee_amount)

    return_amount =
      target_base_amount
      |> Decimal.sub(base_amount)
      |> Decimal.add(fee_amount)

    price = offer_amount |> Decimal.div(return_amount) |> Decimal.round(price_precision)

    {%{
       p
       | status: %{
           s
           | base_amount: to_integer(new_base_amount),
             quote_amount: to_integer(new_quote_amount)
         }
     }, {price, to_integer(offer_amount)}}
  end

  def compute_order(
        %__MODULE__{
          fee: fee,
          price_precision: price_precision,
          status: %Status{base_amount: base_amount, quote_amount: quote_amount} = s
        } = p,
        i,
        :ask
      ) do
    offer_amount = Decimal.mult(i, Decimal.new(base_amount))

    {new_base_amount, target_quote_amount, fee_amount} =
      size_order(base_amount, quote_amount, offer_amount, fee)

    new_quote_amount = Decimal.add(target_quote_amount, fee_amount)

    return_amount =
      target_quote_amount
      |> Decimal.sub(quote_amount)
      |> Decimal.add(fee_amount)

    price = return_amount |> Decimal.div(offer_amount) |> Decimal.round(price_precision)

    {%{
       p
       | status: %{
           s
           | base_amount: to_integer(new_base_amount),
             quote_amount: to_integer(new_quote_amount)
         }
     }, {price, to_integer(offer_amount)}}
  end

  defp size_order(offer_balance, ask_balance, offer_amount, fee) do
    k = Decimal.mult(offer_balance, ask_balance)
    new_amount = Decimal.sub(offer_balance, offer_amount)
    target_amount = Decimal.div(k, new_amount)
    ask_amount = Decimal.sub(target_amount, ask_balance)
    fee_amount = Decimal.mult(ask_amount, fee)
    new_target_amount = Decimal.add(target_amount, fee_amount)

    {new_amount, new_target_amount, fee_amount}
  end

  @doc """
  Returns the ratio of deposits that are deployed into the pool for a given interval configuration
  """
  @spec utilization(__MODULE__.t()) :: Decimal.t()
  def utilization(%__MODULE__{intervals: intervals}) do
    Enum.reduce(intervals, &Decimal.add/2)
  end

  defp to_integer(d), do: d |> Decimal.round(0, :floor) |> Decimal.to_integer()
end
