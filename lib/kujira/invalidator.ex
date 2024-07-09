defmodule Kujira.Invalidator do
  alias Phoenix.PubSub
  use GenServer
  require Logger

  @impl true
  def init(opts) do
    PubSub.subscribe(opts[:pubsub], "tendermint/event/Tx")
    PubSub.subscribe(opts[:pubsub], "tendermint/event/NewBlockHeader")

    {:ok, opts}
  end

  def subscriptions() do
    [
      "message.action='/cosmwasm.wasm.v1.MsgExecuteContract'",
      # This required to catch blocks that the revenue converter trades in EndBlock
      "wasm-trade._contract_address EXISTS"
    ]
  end

  def start_link(default) do
    GenServer.start_link(__MODULE__, default)
  end

  @impl true
  def handle_info(%{TxResult: %{result: %{events: events}}}, state) do
    Enum.flat_map(events, &scan_event/1)
    |> Enum.uniq()
    |> Enum.map(&invalidate/1)

    {:noreply, state}
  end

  def handle_info(
        %{result_end_block: %{events: events}},
        state
      ) do
    Enum.flat_map(events, &scan_event/1)
    |> Enum.uniq()
    |> Enum.map(&invalidate/1)

    {:noreply, state}
  end

  defp scan_event(%{attributes: attributes}) do
    scan_attributes(attributes)
  end

  defp scan_attributes(attributes, collection \\ [])

  defp scan_attributes(
         [
           %{key: "_contract_address", value: value}
           | rest
         ],
         collection
       ) do
    # Here we can just invalidate the address for all protocols.
    # Only the one where it actually matches the protocol will be affected
    scan_attributes(rest, [
      {Kujira.Contract, :query_state_all, [value]},
      {Kujira.Contract, :query_state_smart, [value]},
      {Kujira.Bow, :load_pool, [value]} | collection
    ])
  end

  defp scan_attributes([_ | rest], collection), do: scan_attributes(rest, collection)
  defp scan_attributes([], collection), do: collection

  defp invalidate({module, function, args}) do
    Logger.debug("#{__MODULE__} invalidating #{module}.#{function} #{Enum.join(args, ",")}")
    Memoize.invalidate(module, function, args)
  end
end
