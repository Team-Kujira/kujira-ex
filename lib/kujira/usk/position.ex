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
          "interest_amount" => interest_amount,
          "liquidation_price" => _
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
      {{Market, market_address}, borrower, :borrow}
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
      {{Market, market_address}, borrower, :repay}
      | collection
    ])
  end

  defp scan_events([_ | rest], collection), do: scan_events(rest, collection)
end
