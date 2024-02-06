defmodule Kujira.Usk.Margin do
  @moduledoc """
  A margin contract for USK "wraps" the basic Market contract, allowing minted USK to purchase collateral
  from FIN, before posting it as collateral to a regular position. It also allows a position holder to take
  profits by minting more USK against an appreciating collateral asset, or repaying some of the USK debt to
  cover a falling collateral price

  ## Fields

  * `:fin_pair` - The FIN pair that is used to buy and sell collateral

  * `:market` - The underlying config of the USK CDP market
  """

  alias Kujira.Usk.Market

  defstruct [:fin_pair, :market]

  @type t :: %__MODULE__{
          fin_pair: {Kujira.Fin.Pair, String.t()},
          market: Market.t()
        }

  @spec from_query(String.t(), map()) :: :error | {:ok, __MODULE__.t()}
  def from_query(address, %{
        "fin_address" => fin_address,
        "market" => market
      }) do
    with {:ok, market} <- Market.from_config(address, market) do
      {:ok, %__MODULE__{fin_pair: {Kujira.Fin.Pair, fin_address}, market: market}}
    else
      _ ->
        :error
    end
  end
end
