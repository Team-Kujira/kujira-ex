defmodule Kujira.Token do
  defstruct [:denom, :decimals]
  @type t :: %__MODULE__{denom: String.t(), decimals: integer()}

  @spec from_denom(String.t()) :: Kujira.Token.t()
  def from_denom(denom) do
    %__MODULE__{denom: denom, decimals: 6}
  end
end
