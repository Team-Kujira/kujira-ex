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

  @doc """
  **WIP**

  Simulates a market swap on the book, prior to deduction of fees

  ## Examples

    A 10 unit (with 6dp) buy, with sell orders at 0.09, 0.10, 0.11 and 0.21

    - 10 base tokens are bought for 0.9 quote tokens, 9.1 remaining
    - 15 base tokens are bought for 1.5 quote tokens, 7.6 remaining
    - 18 base tokens are bought for 2.16 quote tokens, 5.44 remaining
    - Final 5.44 quote tokens buy at 0.21 - 25.904761. leaving 14.095239 of orders remaining

    Total return: 10 + 15 + 18 + 25.904761 = 68.904761
    Total spend = 10
    Average price = 0.1451278526

    iex> Kujira.Fin.Book.simulate_market_order(%Kujira.Fin.Book{asks: [
    ...>   %Kujira.Fin.Book.Price{price: Decimal.from_float(0.09), total: 10_000_000},
    ...>   %Kujira.Fin.Book.Price{price: Decimal.from_float(0.10), total: 15_000_000},
    ...>   %Kujira.Fin.Book.Price{price: Decimal.from_float(0.12), total: 18_000_000},
    ...>   %Kujira.Fin.Book.Price{price: Decimal.from_float(0.21), total: 40_000_000},
    ...> ]}, 10_000_000, :buy)
    {:ok, {
      68_904_761,
      Decimal.from_float(0.1451278526),
      %Kujira.Fin.Book{
        asks: [
          %Kujira.Fin.Book.Price{
            price: Decimal.from_float(0.21),
            total: 14_095_239
          }
        ]
      }
    }}
  """

  @spec simulate_market_order(__MODULE__.t(), integer(), :buy | :sell) ::
          {:ok, {integer(), Decimal.t()}, __MODULE__.t()}
          | {:error, :insufficient_liquidity, __MODULE__.t()}

  def simulate_market_order(
        %__MODULE__{asks: [%{price: price, total: total} | asks]} = book,
        amount,
        :buy
      ) do
    max_return = Decimal.mult(price, total)

    if max_return > amount do
      remaining = max(0, amount - max_return)
      simulate_market_order(%{book | asks: asks}, remaining, :buy)
    else
      consumed = Decimal.div(amount, price)
      remaining = 0
      # ask = %{ask | total: total - consumed}
      simulate_market_order(%{book | asks: [ask | asks]}, 0, :buy)
    end
  end

  def simulate_market_order(%__MODULE__{bids: bids}, amount, :sell) do
  end
end
