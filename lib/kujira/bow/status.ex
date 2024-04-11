defmodule Kujira.Bow.Status do
  alias Cosmos.Bank.V1beta1.QuerySupplyOfResponse

  @moduledoc """
  The current status of deposits to an LP pool

  ## Fields
  * `:base_amount` - The total amount of the base token owned by the pool

  * `:quote_amount` - The total amount of the quote token owned by the pool

  * `:lp_amount` - The total amount of LP tokens minted by the pool
  """

  defstruct [:base_amount, :quote_amount, :lp_amount]

  @type t :: %__MODULE__{
          base_amount: non_neg_integer(),
          quote_amount: non_neg_integer(),
          lp_amount: non_neg_integer()
        }

  def from_query(%{"balances" => [base_amount, quote_amount]}, %QuerySupplyOfResponse{
        amount: %{amount: lp_amount}
      }) do
    {base_amount, ""} = Integer.parse(base_amount)
    {quote_amount, ""} = Integer.parse(quote_amount)
    {lp_amount, ""} = Integer.parse(lp_amount)
    %__MODULE__{base_amount: base_amount, quote_amount: quote_amount, lp_amount: lp_amount}
  end
end
