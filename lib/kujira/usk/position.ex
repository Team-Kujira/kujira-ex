defmodule Kujira.Usk.Position do
  @moduledoc """
  An item representing the collateral deposit vs debt position of a particular address for a particular market

  ## Fields

  * `:market` - The market where the position is held

  * `:holder` - The address that owns the position

  * `:collateral_amount` - The amount of collateral_token that has been deposited

  * `:mint_amount` - The amount of USK minted and owed by this position

  * `:interest_amount` - The amount of USK owed in interest. This is ultimately deducted from the collateral during a collateral deposit, withdrawal, or liquidation

  * `:debt_amount` - The total amount of USK owed - mint_amount + interest_amount
  """

  alias Kujira.Usk.Market
  alias Tendermint.Abci.Event
  alias Tendermint.Abci.EventAttribute
  alias Cosmos.Base.Abci.V1beta1.TxResponse

  defstruct [:market, :holder, :collateral_amount, :mint_amount, :interest_amount, :debt_amount]

  @type t :: %__MODULE__{
          market: {Market, String.t()},
          holder: String.t(),
          collateral_amount: integer(),
          mint_amount: integer(),
          interest_amount: integer(),
          debt_amount: integer()
        }

  @typedoc """
  The direction of the adjustment to the Position: collateral deposit, collateral withdrawal, debt borrow (mint), debt repay (burn)

  TODO: Add :liquidation
  """
  @type adjustment :: :deposit | :withdrawal | :borrow | :repay

  @spec from_query(Market.t(), map()) ::
          :error | {:ok, __MODULE__.t()}
  def from_query(
        %Market{address: market},
        %{
          "owner" => owner,
          "deposit_amount" => deposit_amount,
          "mint_amount" => mint_amount,
          "interest_amount" => interest_amount
        }
      ) do
    with {deposit_amount, ""} <- Integer.parse(deposit_amount),
         {mint_amount, ""} <- Integer.parse(mint_amount),
         {interest_amount, ""} <- Integer.parse(interest_amount) do
      {:ok,
       %__MODULE__{
         market: {Market, market},
         holder: owner,
         collateral_amount: deposit_amount,
         mint_amount: mint_amount,
         interest_amount: interest_amount,
         debt_amount: interest_amount + mint_amount
       }}
    else
      _ ->
        :error
    end
  end

  def from_query(%Market{}, _), do: :error

  @spec liquidation_price(Position.t(), Market.t()) :: Decimal.t()
  @doc """
  Calculates a liquidation price for a given position. Quoted in terms of the underlying token decimals

  TODO: Load current and historic interest rates. Calculate accrued interest

  Token where decimals are similar - eg a loan of 1 USDC against 1 KUJI where max ltv is 0.6

  iex> Kujira.Usk.Position.liquidation_price(
  ...>   %Kujira.Usk.Position{debt_amount: 1_000_000, collateral_amount: 1_000_000},
  ...>   %Kujira.Usk.Market{max_ltv: Decimal.from_float(0.6)}
  ...>)
  Decimal.new("1.666666666666666666666666667")

  And eg 1 wETH with 1000 USDC debt. Liq price should be 1666, which with a 12 dp decimal delta is 0.000000001666

  iex> Kujira.Usk.Position.liquidation_price(
  ...>   %Kujira.Usk.Position{debt_amount: 1_000_000_000, collateral_amount: 1_000_000_000_000_000_000},
  ...>   %Kujira.Usk.Market{max_ltv: Decimal.from_float(0.6)}
  ...>)
  Decimal.new("1.666666666666666666666666667E-9")
  """

  def liquidation_price(%__MODULE__{debt_amount: debt_amount}, _)
      when debt_amount == 0 do
    Decimal.new(0)
  end

  def liquidation_price(
        %__MODULE__{
          debt_amount: debt_amount,
          collateral_amount: collateral_amount
        },
        %Market{max_ltv: max_ltv}
      ) do
    debt_amount
    |> Decimal.new()
    |> Decimal.div(collateral_amount |> Decimal.new() |> Decimal.mult(max_ltv))
  end

  @doc """
  Returns all adjustments to positions found in the tx response
  """
  @spec from_tx_response(TxResponse.t()) ::
          list({{Market, String.t()}, String.t(), adjustment}) | nil
  def from_tx_response(response) do
    case scan_events(response.events) do
      [] ->
        nil

      xs ->
        xs
    end
  end

  defp scan_events(events, collection \\ [])
  defp scan_events([], collection), do: collection

  defp scan_events(
         [
           %Event{
             type: "wasm",
             attributes: [
               %EventAttribute{key: "_contract_address", value: market_address},
               %EventAttribute{key: "action", value: "deposit"},
               %EventAttribute{key: "position", value: borrower},
               %EventAttribute{key: "amount", value: _amount}
             ]
           }
           | rest
         ],
         collection
       ) do
    scan_events(rest, [
      {{Market, market_address}, borrower, :deposit}
      | collection
    ])
  end

  defp scan_events(
         [
           %Event{
             type: "wasm",
             attributes: [
               %EventAttribute{key: "_contract_address", value: market_address},
               %EventAttribute{key: "action", value: "withdraw"},
               %EventAttribute{key: "position", value: borrower},
               %EventAttribute{key: "amount", value: _amount}
             ]
           }
           | rest
         ],
         collection
       ) do
    scan_events(rest, [
      {{Market, market_address}, borrower, :withdraw}
      | collection
    ])
  end

  defp scan_events(
         [
           %Event{
             type: "wasm",
             attributes: [
               %EventAttribute{key: "_contract_address", value: market_address},
               %EventAttribute{key: "action", value: "mint"},
               %EventAttribute{key: "position", value: borrower},
               %EventAttribute{key: "amount", value: _amount}
             ]
           }
           | rest
         ],
         collection
       ) do
    scan_events(rest, [
      {{Market, market_address}, borrower, :mint}
      | collection
    ])
  end

  defp scan_events(
         [
           %Event{
             type: "wasm",
             attributes: [
               %EventAttribute{key: "_contract_address", value: market_address},
               %EventAttribute{key: "action", value: "burn"},
               %EventAttribute{key: "position", value: borrower},
               %EventAttribute{key: "amount", value: _amount}
             ]
           }
           | rest
         ],
         collection
       ) do
    scan_events(rest, [
      {{Market, market_address}, borrower, :burn}
      | collection
    ])
  end

  defp scan_events([_ | rest], collection), do: scan_events(rest, collection)
end
