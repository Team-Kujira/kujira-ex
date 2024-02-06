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
end
