defmodule Kujira.Fin.Book do
  @moduledoc """
  The aggregate of all existing orders on the book

  ## Fields
  * `:bids` - A list of bids, descending by price (ie the limit is at index 0)

  * `:asks` - A list of asks, ascending by price (ie the limit is at index 0)
  """
  defmodule Price do
    @moduledoc """
    A specific price point in the order book summary

    ## Fields
    * `:price` - The bid or ask price

    * `:total` - The total amount offered at this price

    * `:side` - Which side of the book this order is on
    """

    defstruct [:price, :total, :side]

    @type side :: :bid | :ask
    @type t :: %__MODULE__{price: Decimal.t(), total: integer(), side: side}

    @spec from_query(side, map()) :: __MODULE__.t()
    def from_query(side, %{
          "quote_price" => quote_price,
          "total_offer_amount" => total_offer_amount
        }) do
      {quote_price, ""} = Decimal.parse(quote_price)
      {total_offer_amount, ""} = Integer.parse(total_offer_amount)

      %__MODULE__{
        side: side,
        total: total_offer_amount,
        price: quote_price
      }
    end
  end

  defstruct [:bids, :asks]

  @type t :: %__MODULE__{bids: list(Price.t()), asks: list(Price.t())}

  @spec from_query(map()) :: :error | {:ok, __MODULE__.t()}
  def from_query(%{
        "base" => asks,
        "quote" => bids
      }) do
    {:ok,
     %__MODULE__{
       asks: Enum.map(asks, &Price.from_query(:ask, &1)),
       bids: Enum.map(bids, &Price.from_query(:bid, &1))
     }}
  end
end
