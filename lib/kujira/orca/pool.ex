defmodule Kujira.Orca.Pool do
  @moduledoc """
  A pool of bid tokens at a specific premium %, for a specific Queue

  ## Fields
  * `:premium` - The premium "charged" above the current market rate (ie the discount that the collateral is bought for)

  * `:total` - The total amount of activated bid token in the pool
  """

  defstruct premium: Decimal.new(0), total: :not_loaded, epoch: :not_loaded

  @type t :: %__MODULE__{
          premium: Decimal.t(),
          total: integer() | :not_loaded,
          epoch: integer() | :not_loaded
        }

  @doc """
  Calculates a new Pool from the config on the Queue
  """
  @spec calculate(Decimal.t(), integer()) :: __MODULE__.t()
  def calculate(premium_rate_per_slot, slot) do
    %__MODULE__{
      premium: slot |> Decimal.new() |> Decimal.mult(premium_rate_per_slot)
    }
  end

  @spec load(map() | nil, __MODULE__.t()) :: __MODULE__.t()
  def load(
        %{
          "current_epoch" => current_epoch,
          "total_bid_amount" => total_bid_amount
        },
        pool
      ) do
    {current_epoch, ""} = Integer.parse(current_epoch)
    {total_bid_amount, ""} = Integer.parse(total_bid_amount)
    %{pool | epoch: current_epoch, total: total_bid_amount}
  end

  def load(nil, pool), do: %{pool | epoch: 0, total: 0}
end
