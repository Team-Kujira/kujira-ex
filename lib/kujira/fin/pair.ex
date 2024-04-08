defmodule Kujira.Fin.Pair do
  @moduledoc """
  An individual exchange pair between a base token and a quote token.

  ## Fields
  * `:address` - The address of the pair

  * `:owner` - The owner of the pair

  * `:token_base` - The base token of the Pair - typically the one that's being traded

  * `:token_quote` - The quote token of the Pair - typically a stablecoin

  * `:price_precision` - The maximum valid decimal places of the human price. Comparable to a tick size

  * `:decimal_delta` - Base decimals - Quote decimals. Allows conversion between "human" prices and "actual" prices with respect to base units of each token

  * `:is_bootstrapping` - A Pair is in Bootstrapping mode until manually launched, in order to prevent large amounts of slippage on new books

  * `:fee_taker` - The amount of a market swap that is sent to the fee collector

  * `:fee_maker` - The amount of a filled and claimed limit order that is sent to the fee collector

  * `:book` - An aggregate summary of all orders in the Pair's order book
  """

  alias Kujira.Token
  alias Kujira.Fin.Book

  defstruct [
    :address,
    :owner,
    :token_base,
    :token_quote,
    :price_precision,
    :decimal_delta,
    :is_bootstrapping,
    :fee_taker,
    :fee_maker,
    :book
  ]

  @type t :: %__MODULE__{
          address: String.t(),
          owner: String.t(),
          token_base: Token.t(),
          token_quote: Token.t(),
          price_precision: integer(),
          decimal_delta: integer(),
          is_bootstrapping: boolean(),
          fee_taker: Decimal.t(),
          fee_maker: Decimal.t(),
          book: :not_loaded | Book.t()
        }

  @spec from_config(String.t(), map()) :: :error | {:ok, __MODULE__.t()}
  def from_config(address, %{
        "owner" => owner,
        "denoms" => [denom_base, denom_quote],
        "price_precision" => %{"decimal_places" => price_precision},
        "decimal_delta" => decimal_delta,
        "is_bootstrapping" => is_bootstrapping,
        "fee_taker" => fee_taker,
        "fee_maker" => fee_maker
      }) do
    with {fee_taker, ""} <- Decimal.parse(fee_taker),
         {fee_maker, ""} <- Decimal.parse(fee_maker) do
      {:ok,
       %__MODULE__{
         address: address,
         owner: owner,
         token_base: Token.from_denom(denom_base),
         token_quote: Token.from_denom(denom_quote),
         price_precision: price_precision,
         decimal_delta: decimal_delta,
         is_bootstrapping: is_bootstrapping,
         fee_taker: fee_taker,
         fee_maker: fee_maker,
         book: :not_loaded
       }}
    else
      _ ->
        :error
    end
  end

  # Original KUJI-axlUSDC pair does not expose fees
  def from_config(address, params) do
    from_config(address, Map.merge(params, %{"fee_maker" => "0.00075", "fee_taker" => "0.0015"}))
  end
end
