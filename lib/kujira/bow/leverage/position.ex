defmodule Kujira.Bow.Leverage.Position do
  @moduledoc """
  An item representing the collateral deposit vs debt position of a particular address for a particular market

  ## Fields


  * `:idx` - Position ID

  * `:holder` - The address that owns the position

  * `:debt_shares_base` - The amount of the base debt token borrowed by this position

  * `:debt_amount_base` - The resultant amount of debt owed, based on the `debt_ratio`

  * `:debt_shares_quote` - The amount of the quote debt token borrowed by this position

  * `:debt_amount_quote` - The resultant amount of debt owed, quoted on the `debt_ratio`

  * `:lp_amount` - The total LP token collateral owned by the position

  * `:collateral_amount_base` - The base amount that the current LP token is worth

  * `:collateral_amount_quote` - The quote amount that the current LP token is worth
  """

  alias Kujira.Ghost.Vault
  alias Kujira.Bow.Status

  defstruct [
    :idx,
    :holder,
    :debt_shares_base,
    :debt_amount_base,
    :debt_shares_quote,
    :debt_amount_quote,
    :lp_amount,
    :collateral_amount_base,
    :collateral_amount_quote
  ]

  @type t :: %__MODULE__{
          idx: String.t(),
          holder: String.t(),
          debt_shares_base: integer(),
          debt_amount_base: integer(),
          debt_shares_quote: integer(),
          debt_amount_quote: integer(),
          lp_amount: integer(),
          collateral_amount_base: integer(),
          collateral_amount_quote: integer()
        }

  @spec from_query(Vault.t(), Vault.t(), Status.t(), map()) ::
          :error | {:ok, __MODULE__.t()}
  def from_query(
        %Vault{status: %Vault.Status{debt_ratio: debt_ratio_base}},
        %Vault{status: %Vault.Status{debt_ratio: debt_ratio_quote}},
        %Status{} = status,
        %{
          "idx" => idx,
          "holder" => holder,
          "debt_shares" => [debt_shares_base, debt_shares_quote],
          "lp_amount" => lp_amount
        }
      ) do
    with {lp_amount, ""} <- Integer.parse(lp_amount),
         {debt_shares_base, ""} <- Integer.parse(debt_shares_base),
         {debt_shares_quote, ""} <- Integer.parse(debt_shares_quote) do
      debt_amount_base =
        debt_shares_base
        |> Decimal.new()
        |> Decimal.mult(debt_ratio_base)
        |> Decimal.round(0, :ceiling)
        |> Decimal.to_integer()

      debt_amount_quote =
        debt_shares_quote
        |> Decimal.new()
        |> Decimal.mult(debt_ratio_quote)
        |> Decimal.round(0, :ceiling)
        |> Decimal.to_integer()

      collateral_amount_base = lp_amount * status.base_amount / status.lp_amount
      collateral_amount_quote = lp_amount * status.quote_amount / status.lp_amount

      {:ok,
       %__MODULE__{
         idx: idx,
         holder: holder,
         lp_amount: lp_amount,
         debt_shares_base: debt_shares_base,
         debt_amount_base: debt_amount_base,
         debt_shares_quote: debt_shares_quote,
         debt_amount_quote: debt_amount_quote,
         collateral_amount_base: collateral_amount_base,
         collateral_amount_quote: collateral_amount_quote
       }}
    end
  end

  def from_query(%Vault{}, %Vault{}, %Status{}, _), do: :error
end
