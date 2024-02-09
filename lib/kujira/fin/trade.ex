defmodule Kujira.Fin.Trade do
  @moduledoc """
  An individual trade on an individual pair. For a market swap where orders at multiple price
  points are consumed, the trade is aggregated across all orders at each price.

  ## Fields

  * `:id` - A unique ID for the trade; `"\#{txhash}-\#{idx}"`

  * `:pair` - The pair the trade was executed on

  * `:price` - The price the trade was executed at

  * `:direction` - Whether the taker of the trade was a buyer or a seller

  * `:amount_base` - The amount of the base token traded

  * `:amount_quote` - The amount of the quote token traded

  * `:txhash` - The hash of the transaction the trade was executed in

  * `:height` - The chain height when the trade was executed

  * `:timestamp` - The timestamp of the trade

  * `:idx` - The index of the trade within the transaction it was executed in.
  """

  alias Kujira.Fin.Pair
  alias Tendermint.Abci.EventAttribute

  defstruct [
    :id,
    :pair,
    :price,
    :direction,
    :amount_base,
    :amount_quote,
    :txhash,
    :height,
    :timestamp,
    :idx
  ]

  @type direction :: :buy | :sell

  @type t :: %__MODULE__{
          id: String.t(),
          pair: {Pair, String.t()},
          price: Decimal.t(),
          direction: direction,
          amount_base: integer(),
          amount_quote: integer(),
          txhash: String.t(),
          height: integer(),
          timestamp: DateTime.t(),
          idx: integer()
        }

  @doc """
  Extracts all trade events from a tx_response.

  N.B: Prior to height 6_549_066 (2022-12-26T10:15:13+00:00), the FIN contract did not emit the `type` event which classifies
  the Trade as a buy or a sell, and trades will not be collected by this function
  """
  @spec from_tx_response(TxResponse.t()) :: list(__MODULE__.t()) | nil
  def from_tx_response(%{
        txhash: txhash,
        height: height,
        timestamp: timestamp,
        events: events
      }) do
    case events |> Enum.flat_map(& &1.attributes) |> scan_attributes() do
      [] ->
        nil

      xs ->
        {:ok, timestamp, 0} = DateTime.from_iso8601(timestamp)

        Enum.map(
          xs,
          &%{
            &1
            | id: "#{txhash}-#{to_string(&1.idx)}",
              height: height,
              txhash: txhash,
              timestamp: timestamp
          }
        )
    end
  end

  defp scan_attributes(attrs, collection \\ [])

  defp scan_attributes(
         [
           %EventAttribute{key: "market", value: pair},
           %EventAttribute{key: "base_amount", value: base_amount},
           %EventAttribute{key: "quote_amount", value: quote_amount},
           %EventAttribute{key: "type", value: type} | rest
         ],
         collection
       )
       when base_amount != "0" do
    base_amount = String.to_integer(base_amount)
    quote_amount = String.to_integer(quote_amount)

    trade = %__MODULE__{
      idx: Enum.count(collection),
      pair: {Pair, pair},
      amount_base: base_amount,
      amount_quote: quote_amount,
      price: Decimal.from_float(quote_amount / base_amount),
      direction: String.to_existing_atom(type)
    }

    scan_attributes(rest, [trade | collection])
  end

  defp scan_attributes([_ | rest], collection), do: scan_attributes(rest, collection)
  defp scan_attributes([], collection), do: collection
end
