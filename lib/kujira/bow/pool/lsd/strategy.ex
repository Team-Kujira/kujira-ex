defmodule Kujira.Bow.Pool.Lsd.Strategy do
  @moduledoc """
  The specific configuration for the Lsd strategy.

  * `:ask_fee` - The % price difference between the expected price and the calculated ask price for each order
  * `:ask_utilization` - The fraction of the available quote denom that is deployed to the order. Prevent the whole vault from being wiped out in a single trade
  * `:bid_fee` - As ask but on the bid side
  * `:bid_factor` - The adjustment of the bid_fee based on the current token balances (quote_balance / base_value) * bid_factor. So eg to decrease the bid_fee (by reducing the price) by 5% when the pool is balanced  90 - 10, the bid_factor should be 0.00555.
  * `:bid_utilization` - As ask but on the bid side
  * `:bid_count` - Total bid orders placed
  """

  defstruct [
    :ask_fee,
    :ask_utilization,
    :bid_fee,
    :bid_factor,
    :bid_utilization,
    :bid_count
  ]

  @type t :: %__MODULE__{
          ask_fee: Decimal.t(),
          ask_utilization: Decimal.t(),
          bid_fee: Decimal.t(),
          bid_factor: Decimal.t(),
          bid_utilization: Decimal.t(),
          bid_count: non_neg_integer()
        }

  @spec from_config(map()) ::
          {:error, :invalid_config} | {:ok, __MODULE__.t()}
  def from_config(%{
        "ask_fee" => ask_fee,
        "ask_utilization" => ask_utilization,
        "bid_fee" => bid_fee,
        "bid_factor" => bid_factor,
        "bid_utilization" => bid_utilization,
        "bid_count" => bid_count
      }) do
    with {ask_fee, ""} <- Decimal.parse(ask_fee),
         {ask_utilization, ""} <- Decimal.parse(ask_utilization),
         {bid_fee, ""} <- Decimal.parse(bid_fee),
         {bid_factor, ""} <- Decimal.parse(bid_factor),
         {bid_utilization, ""} <- Decimal.parse(bid_utilization) do
      {:ok,
       %__MODULE__{
         ask_fee: ask_fee,
         ask_utilization: ask_utilization,
         bid_fee: bid_fee,
         bid_factor: bid_factor,
         bid_utilization: bid_utilization,
         bid_count: bid_count
       }}
    else
      :error ->
        {:error, :invalid_config}
    end
  end

  def from_config(_), do: {:error, :invalid_config}
end
