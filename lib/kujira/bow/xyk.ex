defmodule Kujira.Bow.Xyk do
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

  @spec from_config(GRPC.Channel.t(), String.t(), map()) :: :error | {:ok, __MODULE__.t()}
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
      _ ->
        :error
    end
  end
end
