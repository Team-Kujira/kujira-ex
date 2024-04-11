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
  alias Tendermint.Abci.Event
  alias Tendermint.Abci.EventAttribute
  alias Cosmos.Base.Abci.V1beta1.TxResponse

  defstruct [:market, :holder, :collateral_amount, :debt_shares, :debt_amount]

  @type t :: %__MODULE__{
          market: {Kujira.Ghost.Market, String.t()},
          holder: String.t(),
          collateral_amount: integer(),
          debt_shares: integer(),
          debt_amount: integer()
        }

  @typedoc """
  The direction of the adjustment to the Position: collateral deposit, collateral withdrawal, debt borrow, debt repay

  TODO: Add :liquidation
  """
  @type adjustment :: :deposit | :withdrawal | :borrow | :repay

  @spec from_query(Kujira.Ghost.Market.t(), Kujira.Ghost.Vault.t(), map()) ::
          :error | {:ok, __MODULE__.t()}
  def from_query(
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
      {:ok,
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
       }}
    else
      _ ->
        :error
    end
  end

  def from_query(%Market{}, %Vault{}, _), do: :error

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
             type: "wasm-ghost/deposit",
             attributes: [
               %EventAttribute{key: "_contract_address", value: market_address},
               %EventAttribute{key: "depositor", value: borrower},
               %EventAttribute{key: "collateral_added", value: _},
               %EventAttribute{key: "position_total", value: _}
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
             type: "wasm-ghost/withdraw",
             attributes: [
               %EventAttribute{key: "_contract_address", value: market_address},
               %EventAttribute{key: "destination", value: _},
               %EventAttribute{key: "depositor", value: borrower},
               %EventAttribute{key: "amount", value: _},
               %EventAttribute{key: "position_total", value: _}
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
             type: "wasm-ghost/borrow",
             attributes: [
               %EventAttribute{key: "_contract_address", value: market_address},
               %EventAttribute{key: "borrower", value: borrower},
               %EventAttribute{key: "borrowed", value: _},
               %EventAttribute{key: "position_total", value: _}
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
             type: "wasm-ghost/repay",
             attributes: [
               %EventAttribute{key: "_contract_address", value: market_address},
               %EventAttribute{key: "borrower", value: borrower},
               %EventAttribute{key: "repaid", value: _},
               %EventAttribute{key: "position_total", value: _}
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
