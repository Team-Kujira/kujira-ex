defmodule Kujira.Bow.Leverage.Position do
  @moduledoc """
  An item representing the collateral deposit vs debt position of a particular address for a particular market

  ## Fields


  * `:idx` - Position ID

  * `:bow` - The BOW pool for this position

  * `:leverage` - The leverage contract that manages this position
  .
  * `:holder` - The address that owns the position

  * `:debt_shares_base` - The amount of the base debt token borrowed by this position

  * `:debt_amount_base` - The resultant amount of debt owed, based on the `debt_ratio`

  * `:debt_shares_quote` - The amount of the quote debt token borrowed by this position

  * `:debt_amount_quote` - The resultant amount of debt owed, quoted on the `debt_ratio`

  * `:lp_amount` - The total LP token collateral owned by the position

  * `:collateral_amount_base` - The base amount that the current LP token is worth

  * `:collateral_amount_quote` - The quote amount that the current LP token is worth
  """

  alias Kujira.Bow.Pool.Stable
  alias Kujira.Bow.Pool.Xyk
  alias Kujira.Bow.Leverage
  alias Kujira.Ghost.Vault
  alias Kujira.Bow.Status

  defstruct [
    :idx,
    :bow,
    :leverage,
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
          bow: {Xyk | Stable, String.t()},
          leverage: {Leverage, String.t()},
          holder: String.t(),
          debt_shares_base: integer(),
          debt_amount_base: integer(),
          debt_shares_quote: integer(),
          debt_amount_quote: integer(),
          lp_amount: integer(),
          collateral_amount_base: integer(),
          collateral_amount_quote: integer()
        }

  @spec from_query(Leverage.t(), Vault.t(), Vault.t(), Xyk.t() | Stable.t(), map()) ::
          :error | {:ok, __MODULE__.t()}
  def from_query(
        %Leverage{address: address},
        %Vault{status: %Vault.Status{debt_ratio: debt_ratio_base}},
        %Vault{status: %Vault.Status{debt_ratio: debt_ratio_quote}},
        %struct{address: bow, status: %Status{} = status},
        %{
          "idx" => idx,
          "holder" => holder,
          "debt_shares" => [debt_shares_base, debt_shares_quote],
          "lp_amount" => lp_amount
        }
      )
      when is_binary(debt_shares_base) and is_binary(debt_shares_quote) do
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

      collateral_amount_base =
        Decimal.div(lp_amount, status.lp_amount)
        |> Decimal.mult(status.base_amount)

      collateral_amount_quote =
        Decimal.div(lp_amount, status.lp_amount)
        |> Decimal.mult(status.quote_amount)

      {:ok,
       %__MODULE__{
         idx: idx,
         bow: {struct, bow},
         leverage: {Leverage, address},
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

  def from_query(
        %Leverage{} = l,
        %Vault{debt_token: %{denom: debt_denom_base}} = b,
        %Vault{debt_token: %{denom: debt_denom_quote}} = q,
        p,
        %{
          "debt_shares" => shares
        } = res
      )
      when is_list(shares) do
    debt_shares_base =
      shares |> Enum.find(%{}, &(&1["denom"] == debt_denom_base)) |> Map.get("amount", "0")

    debt_shares_quote =
      shares |> Enum.find(%{}, &(&1["denom"] == debt_denom_quote)) |> Map.get("amount", "0")

    from_query(l, b, q, p, Map.put(res, "debt_shares", [debt_shares_base, debt_shares_quote]))
  end

  def from_query(%Leverage{}, %Vault{}, %Vault{}, %Xyk{}, _), do: :error
  def from_query(%Leverage{}, %Vault{}, %Vault{}, %Stable{}, _), do: :error

  @doc """
  Returns the liquidation price of the position
  """
  @spec liquidation_price(
          Bow.Leverage.t(),
          __MODULE__.t()
        ) :: Decimal.t()
  def liquidation_price(%Leverage{max_ltv: max_ltv}, %__MODULE__{
        debt_amount_base: debt_amount_base,
        debt_amount_quote: debt_amount_quote,
        collateral_amount_base: collateral_amount_base,
        collateral_amount_quote: collateral_amount_quote
      }) do
    d = max_ltv |> Decimal.mult(collateral_amount_base) |> Decimal.sub(debt_amount_base)

    debt_amount_quote
    |> Decimal.sub(Decimal.mult(max_ltv, collateral_amount_quote))
    |> Decimal.div(d)
  end
end
