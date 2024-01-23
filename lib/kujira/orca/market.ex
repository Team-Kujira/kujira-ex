defmodule Kujira.Orca.Market do
  @moduledoc """
  We define a Market, as far as Orca is concerned, in order to be able to standardise
  and aggregate the health of the various markets that any given liquidation queue can liquidate
  """

  alias Kujira.Token

  defstruct [:collateral_token, :bid_token]
  @type t :: %__MODULE__{collateral_token: Token.t()}
end
