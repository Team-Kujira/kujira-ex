defmodule Kujira.Orca.Market do
  @moduledoc """
  We define a Market, as far as Orca is concerned, in order to be able to standardise
  and aggregate the health of the various markets that any given liquidation queue can liquidate

  ## Fields
  * `:queue` - The Queue that will process the liquidation from the :address

  * `:address` - The address of the market that uses this Queue

  * `:health` - A bucketed map of market health -
    key: liquidation price,
    value: total collateral between this (inclusive) and the previous liquidation price (exclusive)
  """
  alias Kujira.Orca.Queue

  defstruct [:queue, :address, :health]
  @type t :: %__MODULE__{queue: {Queue, String.t()}, address: {atom(), String.t()}, health: map()}
end
