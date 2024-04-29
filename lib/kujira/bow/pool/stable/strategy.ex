defmodule Kujira.Bow.Pool.Stable.Strategy do
  @moduledoc """
  The specific configuration for the Stable strategy.


  * `:target_price` - The fixed price that the two assets should be trading at
  * `:ask_fee` - The % price difference between the expected price and the calculated ask price for each order
  * `:ask_factor` - The adjustment of the ask_fee based on the current token balances (quote_balance / base_value) * ask_factor. So eg to decrease the ask_fee (by reducing the price) by 5% when the pool is balanced  10 - 90, the ask_factor should be 0.00555.
  * `:ask_utilization` - The fraction of the available quote denom that is deployed to the order. Prevent the whole vault from being wiped out in a single trade
  * `:ask_count` - Total ask orders placed
  * `:bid_fee` - As ask but on the bid side
  * `:bid_factor` - As ask but on the bid side
  * `:bid_utilization` - As ask but on the bid side
  * `:bid_count` - As ask but on the bid side
  """

  defstruct [
    :target_price,
    :ask_fee,
    :ask_factor,
    :ask_utilization,
    :ask_count,
    :bid_fee,
    :bid_factor,
    :bid_utilization,
    :bid_count
  ]

  @type t :: %__MODULE__{
          target_price: Decimal.t(),
          ask_fee: Decimal.t(),
          ask_factor: Decimal.t(),
          ask_utilization: Decimal.t(),
          ask_count: non_neg_integer(),
          bid_fee: Decimal.t(),
          bid_factor: Decimal.t(),
          bid_utilization: Decimal.t(),
          bid_count: non_neg_integer()
        }

  @spec from_config(map()) ::
          {:error, :invalid_config} | {:ok, __MODULE__.t()}
  def from_config(%{
        "target_price" => target_price,
        "ask_fee" => ask_fee,
        "ask_factor" => ask_factor,
        "ask_utilization" => ask_utilization,
        "ask_count" => ask_count,
        "bid_fee" => bid_fee,
        "bid_factor" => bid_factor,
        "bid_utilization" => bid_utilization,
        "bid_count" => bid_count
      }) do
    with {target_price, ""} <- Decimal.parse(target_price),
         {ask_fee, ""} <- Decimal.parse(ask_fee),
         {ask_factor, ""} <- Decimal.parse(ask_factor),
         {ask_utilization, ""} <- Decimal.parse(ask_utilization),
         {bid_fee, ""} <- Decimal.parse(bid_fee),
         {bid_factor, ""} <- Decimal.parse(bid_factor),
         {bid_utilization, ""} <- Decimal.parse(bid_utilization) do
      {:ok,
       %__MODULE__{
         target_price: target_price,
         ask_fee: ask_fee,
         ask_factor: ask_factor,
         ask_utilization: ask_utilization,
         ask_count: ask_count,
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
