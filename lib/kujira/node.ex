defmodule Kujira.Node do
  defmacro __using__(opts) do
    pubsub = Keyword.get(opts, :pubsub, Kujira.PubSub)

    quote do
      use Supervisor
      require Logger

      defmodule Websocket do
        use Kujira.Node.Websocket,
          pubsub: unquote(pubsub),
          subscriptions: Keyword.get(unquote(opts), :subscriptions, [])
      end

      defmodule Grpc do
        use Kujira.Node.Grpc
      end

      def start_link(opts) do
        Supervisor.start_link(__MODULE__, :ok, opts)
      end

      @impl true
      def init(_) do
        config = Application.get_env(:kujira, Kujira.Node, [])

        socket_opts = Keyword.merge(config, unquote(opts))

        children = [
          {__MODULE__.Grpc, config},
          {__MODULE__.Websocket, socket_opts}
        ]

        Supervisor.init(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
      end

      def channel() do
        __MODULE__.Grpc.channel()
      end

      def subscribe(topic) do
        Phoenix.PubSub.subscribe(unquote(pubsub), topic)
      end
    end
  end
end
