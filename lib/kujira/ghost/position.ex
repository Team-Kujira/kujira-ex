defmodule Kujira.Ghost.Position do
  @moduledoc """
  An item representing the collateral deposit vs debt position of a particular address for a particular market

  ## Fields

  * `:market` - The market where the position is held

  * `:holder` - The address that owns the position

  * `:collateral_amount` - The amount of collateral_token that has been deposited

  * `:debt_shares` - The amount of debt_token minted and owned by this position

  * `:debt_amount` - The resultant amount of debt owed, based on the `debt_ratio`
  """

  alias Kujira.Ghost.Market
  alias Kujira.Ghost.Vault

  defstruct [:market, :holder, :collateral_amount, :debt_shares, :debt_amount]

  @type t :: %__MODULE__{
          market: {Kujira.Ghost.Market, String.t()},
          holder: String.t(),
          collateral_amount: integer(),
          debt_shares: integer(),
          debt_amount: integer()
        }

  @spec from_response(Kujira.Ghost.Market.t(), Kujira.Ghost.Vault.t(), map()) ::
          :error | __MODULE__.t()
  def from_response(
        %Market{address: market},
        %Vault{status: %Vault.Status{debt_ratio: debt_ratio}},
        %{
          "holder" => holder,
          "collateral_amount" => collateral_amount,
          "debt_shares" => debt_shares
        }
      ) do
    with {collateral_amount, ""} <- Integer.parse(collateral_amount),
         {debt_shares, ""} <- Integer.parse(debt_shares) do
      %__MODULE__{
        market: {Market, market},
        holder: holder,
        collateral_amount: collateral_amount,
        debt_shares: debt_shares,
        debt_amount:
          debt_shares
          |> Decimal.new()
          |> Decimal.mult(debt_ratio)
          # Debt is always rounded up
          |> Decimal.round(0, :ceiling)
          |> Decimal.to_integer()
      }
    else
      _ ->
        :error
    end
  end
end
