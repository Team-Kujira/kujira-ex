defmodule Kujira.Fin.Order do
  @moduledoc """
  An individual order placed on a Pair
  """

  alias Kujira.Fin.Pair
  alias Kujira.Token

  defstruct [
    :pair,
    :id,
    :owner,
    :price,
    :offer_token,
    :original_offer_amount,
    :remaining_offer_amount,
    :filled_amount,
    :created_at
  ]

  @type t :: %__MODULE__{
          pair: {Pair, String.t()},
          id: String.t(),
          owner: String.t(),
          price: Decimal.t(),
          offer_token: Token.t(),
          original_offer_amount: integer(),
          remaining_offer_amount: integer(),
          filled_amount: integer(),
          created_at: DateTime.t()
        }

  def from_query(channel, %Pair{address: pair}, %{
        "created_at" => created_at,
        "filled_amount" => filled_amount,
        "idx" => idx,
        "offer_amount" => offer_amount,
        "offer_denom" => %{
          "native" => offer_denom
        },
        "original_offer_amount" => original_offer_amount,
        "owner" => owner,
        "quote_price" => quote_price
      }) do
    with {created_at, ""} <- Integer.parse(created_at),
         {:ok, created_at} <- DateTime.from_unix(created_at, :nanosecond),
         {filled_amount, ""} <- Integer.parse(filled_amount),
         {original_offer_amount, ""} <- Integer.parse(original_offer_amount),
         {offer_amount, ""} <- Integer.parse(offer_amount),
         {quote_price, ""} <- Decimal.parse(quote_price),
         {:ok, offer_token} <- Token.from_denom(channel, offer_denom) do
      %__MODULE__{
        pair: {Pair, pair},
        id: idx,
        owner: owner,
        price: quote_price,
        offer_token: offer_token,
        original_offer_amount: original_offer_amount,
        remaining_offer_amount: offer_amount,
        filled_amount: filled_amount,
        created_at: created_at
      }
    end
  end
end
