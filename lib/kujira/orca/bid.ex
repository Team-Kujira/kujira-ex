defmodule Kujira.Orca.Bid do
  @moduledoc """
  A bid placed by a user to buy liquidated collateral at a specific discount from the market price

  ## Fields
  * `:id` - The unique ID of the bid

  * `:bidder` - The address that submitted the bid

  * `:delegate` - An optional account that can activate the bid on behalf of the bidder

  * `:bid_amount` - The remaining amount of the bid_token

  * `:filled_amount` - The amount of collateral available for withdrawal

  * `:premium` - The bid discount on the market rate

  * `:activation_time` - When not nil, the bid must be activated at or after this time
  """

  alias Cosmos.Base.Abci.V1beta1.TxResponse
  alias Kujira.Orca.Queue
  alias Tendermint.Abci.Event
  alias Tendermint.Abci.EventAttribute

  defstruct [:id, :bidder, :delegate, :bid_amount, :filled_amount, :premium, :activation_time]

  @type t :: %__MODULE__{
          id: String.t(),
          bidder: String.t(),
          delegate: String.t() | nil,
          bid_amount: integer(),
          filled_amount: integer(),
          premium: Decimal.t(),
          activation_time: DateTime.t() | nil | :not_loaded
        }

  @spec from_query(Kujira.Orca.Queue.t(), map()) :: Kujira.Orca.Bid.t() | nil
  def from_query(%Queue{} = queue, %{
        "idx" => id,
        "bidder" => bidder,
        "delegate" => delegate,
        "amount" => bid_amount,
        "pending_liquidated_collateral" => filled_amount,
        "premium_slot" => premium_slot,
        "wait_end" => wait_end
      }) do
    {bid_amount, ""} = Integer.parse(bid_amount)
    {filled_amount, ""} = Integer.parse(filled_amount)

    activation_time =
      case wait_end do
        nil -> nil
        seconds -> DateTime.from_unix!(seconds)
      end

    %__MODULE__{
      id: id,
      bidder: bidder,
      delegate: delegate,
      bid_amount: bid_amount,
      filled_amount: filled_amount,
      premium: queue.bid_pools |> Enum.at(premium_slot) |> Map.get(:premium),
      activation_time: activation_time
    }
  end

  def from_query(_, _), do: nil

  @doc """
  Returns all new bids found in a specific transaction
  """
  @spec from_tx_response(GRPC.Channel.t(), TxResponse.t()) ::
          list({String.t(), __MODULE__.t()}) | nil
  def from_tx_response(channel, response) do
    case scan_events(channel, response.events) do
      [] ->
        nil

      xs ->
        xs
    end
  end

  defp scan_events(channel, events, collection \\ [])
  defp scan_events(_channel, [], collection), do: collection

  defp scan_events(
         channel,
         [
           %Event{
             type: "transfer",
             attributes: [_, %EventAttribute{key: "sender", value: bidder_address}, _]
           },
           _,
           %Event{
             type: "wasm",
             attributes: [
               %EventAttribute{key: "_contract_address", value: queue_address},
               %EventAttribute{key: "action", value: "submit_bid"},
               %EventAttribute{key: "bid_idx", value: bid_idx},
               %EventAttribute{key: "amount", value: amount},
               %EventAttribute{key: "premium_slot", value: premium_slot}
             ]
           }
           | rest
         ],
         collection
       ) do
    {:ok, queue} = Kujira.Orca.get_queue(channel, queue_address)

    scan_events(channel, rest, [
      {queue_address,
       %__MODULE__{
         id: bid_idx,
         bidder: bidder_address,
         bid_amount: String.to_integer(amount),
         filled_amount: 0,
         premium:
           queue.bid_pools |> Enum.at(String.to_integer(premium_slot)) |> Map.get(:premium),
         activation_time: :not_loaded
       }}
      | collection
    ])
  end

  defp scan_events(channel, [_ | rest], collection), do: scan_events(channel, rest, collection)
end
