defmodule Kujira.Node.Websocket do
  defmacro __using__(opts) do
    pubsub = Keyword.get(opts, :pubsub)

    quote do
      use WebSockex
      require Logger

      def start_link(config) do
        endpoint = config[:websocket]
        subscriptions = Keyword.get(config, :subscriptions, [])
        Logger.info("#{__MODULE__} Starting node websocket: #{endpoint}")
        {:ok, pid} = WebSockex.start_link("#{endpoint}/websocket", __MODULE__, %{})
        for {s, idx} <- Enum.with_index(subscriptions), do: subscribe(pid, idx, s)
        {:ok, pid}
      end

      def handle_connect(_conn, state) do
        Logger.info("#{__MODULE__} Connected")

        {:ok, state}
      end

      def handle_disconnect(status, _state) do
        raise "#{__MODULE__} Disconnected"
      end

      def handle_frame({:text, msg}, state) do
        case Jason.decode(msg, keys: :atoms) do
          {:ok, %{id: id, result: %{data: %{type: t, value: v}}}} ->
            Logger.info("#{__MODULE__} Subscription #{id} event #{t}")
            Phoenix.PubSub.broadcast(unquote(pubsub), t, v)

            {:ok, state}

          {:ok, %{id: id, jsonrpc: "2.0", result: %{}}} ->
            Logger.info("#{__MODULE__} Subscription #{id} successful")
            {:ok, state}

          _ ->
            {:ok, state}
        end
      end

      def handle_cast({:send, {_type, msg} = frame}, state) do
        Logger.debug("#{__MODULE__} [send] #{msg}")

        {:reply, frame, state}
      end

      defp subscribe(pid, id, query) do
        message =
          Jason.encode!(%{
            jsonrpc: "2.0",
            method: "subscribe",
            id: id,
            params: %{
              query: query
            }
          })

        WebSockex.send_frame(pid, {:text, message})
      end
    end
  end
end
