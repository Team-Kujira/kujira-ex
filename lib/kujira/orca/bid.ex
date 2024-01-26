defmodule Kujira.Orca.Bid do
  @moduledoc """
  A bid placed by a user to buy liquidated collateral at a specific discount from the market price

  ## Fields
  * `:id` - The unique ID of the bid

  * `:bid_amount` - The remaining amount of the bid_token

  * `:filled_amount` - The amount of collateral available for withdrawal

  * `:premium` - The bid discount on the market rate

  * `:activation_time` - When not nil, the bid must be activated at or after this time
  """

  alias Kujira.Orca.Queue

  defstruct [:id, :bidder, :bid_amount, :filled_amount, :premium, :activation_time]

  @type t :: %__MODULE__{
          id: String.t(),
          bidder: String.t(),
          bid_amount: integer(),
          filled_amount: integer(),
          premium: Decimal.t(),
          activation_time: DateTime.t() | nil
        }

  def from_query(%Queue{} = queue, %{
        "idx" => id,
        "bidder" => bidder,
        "amount" => bid_amount,
        "pending_liquidated_collateral" => filled_amount,
        "premium_slot" => premium_slot,
        "wait_end" => wait_end
      }) do
    {bid_amount, ""} = Integer.parse(bid_amount)
    {filled_amount, ""} = Integer.parse(filled_amount)

    activation_time =
      case wait_end do
        nil -> nil
        seconds -> DateTime.from_unix(seconds)
      end

    %__MODULE__{
      id: id,
      bidder: bidder,
      bid_amount: bid_amount,
      filled_amount: filled_amount,
      premium: queue.bid_pools |> Enum.at(premium_slot) |> Map.get(:premium),
      activation_time: activation_time
    }
  end
end
