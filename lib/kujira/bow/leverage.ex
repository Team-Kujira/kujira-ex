defmodule Kujira.Bow.Leverage do
  @moduledoc """
  A CDP contract that integrates BOW with GHOST, allowing LP tokens to be used as collateral when borrowing the underlying tokens
  that make up the LP position.

  This allows an LP-er to provide eg only the base asset of a pair, and borrow the stable quote-side of the position, in order to avoid having
  to sell any of their position in order to provide liquidity.
  """
end
