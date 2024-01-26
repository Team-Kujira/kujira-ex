defmodule Kujira.Orca.Liquidation do
  @moduledoc """
  An individual liquidation, as seen by Orca. These can be duplicated as the liquidating market
  will also have something that represents the liquidation, but these may be different.

   ## Fields
  * `:txhash` - The hash of the transaction the liqdation ocurred in

  * `:height` - The block height that included the transaction

  * `:timestamp` - The timestamp of the block

  * `:queue_address` - The address of the liquidation queue that processed the liquidation

  * `:market_address` - The market that requested the liquidation

  * `:collateral_amount` - The amount of collateral liquidated by the market

  * `:bid_amount` - The amount of bid_token that was consumed during the liquidation

  * `:repay_amount` - The amount of bid_token that was returned to the liquidating market

  * `:fee_amount` - The amount of the bid_token that was retained as a fee
  """

  alias Cosmos.Base.Abci.V1beta1.TxResponse
  alias Tendermint.Abci.Event
  alias Tendermint.Abci.EventAttribute

  defstruct [
    :txhash,
    :height,
    :timestamp,
    :queue_address,
    :market_address,
    :bid_amount,
    :repay_amount,
    :collateral_amount,
    :fee_amount
  ]

  @type t :: %__MODULE__{
          txhash: String.t(),
          height: integer(),
          timestamp: DateTime.t(),
          queue_address: String.t(),
          market_address: String.t(),
          bid_amount: integer(),
          repay_amount: integer(),
          collateral_amount: integer(),
          fee_amount: integer()
        }

  @spec from_tx_response(TxResponse.t()) :: list(__MODULE__.t()) | nil
  def from_tx_response(response) do
    case scan_events(response.events) do
      [] ->
        nil

      xs ->
        {:ok, timestamp, 0} = DateTime.from_iso8601(response.timestamp)

        Enum.map(
          xs,
          &%{
            &1
            | height: response.height,
              txhash: response.txhash,
              timestamp: timestamp
          }
        )
    end
  end

  defp scan_events(events, collection \\ [])
  defp scan_events([], collection), do: collection

  defp scan_events(
         [
           %Event{
             type: "transfer",
             attributes: [
               %EventAttribute{key: "amount"},
               %EventAttribute{key: "recipient"},
               %EventAttribute{key: "sender", value: market_address}
             ]
           },
           %Event{
             type: "execute",
             attributes: [
               %EventAttribute{key: "_contract_address"}
             ]
           },
           %Event{
             type: "wasm",
             attributes: [
               %EventAttribute{key: "_contract_address", value: queue_address},
               %EventAttribute{key: "action", value: "execute_bid"},
               %EventAttribute{key: "bid_amount", value: bid_amount},
               %EventAttribute{key: "collateral_amount", value: collateral_amount},
               %EventAttribute{key: "liquidation_fee", value: liquidation_fee},
               %EventAttribute{key: "repay_amount", value: repay_amount}
             ]
           }
           | rest
         ],
         collection
       ) do
    scan_events(rest, [
      %__MODULE__{
        queue_address: queue_address,
        market_address: market_address,
        bid_amount: String.to_integer(bid_amount),
        repay_amount: String.to_integer(repay_amount),
        collateral_amount: String.to_integer(collateral_amount),
        fee_amount: String.to_integer(liquidation_fee)
      }
      | collection
    ])
  end

  defp scan_events([_ | rest], collection), do: scan_events(rest, collection)
end
