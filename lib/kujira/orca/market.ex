defmodule Kujira.Orca.Market do
  @moduledoc """
  We define a Market, as far as Orca is concerned, in order to be able to standardise
  and aggregate the health of the various markets that any given liquidation queue can liquidate

  ## Fields
  * `:address` - The address of the market

  * `:health` - A bucketed map of market health -
    key: liquidation price,
    value: total collateral between this (inclusive) and the previous liquidation price (exclusive)
  """

  defstruct [:address, :health]
  @type t :: %__MODULE__{address: String.t(), health: map()}
end
