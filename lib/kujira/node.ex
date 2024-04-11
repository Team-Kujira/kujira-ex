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
        config = Application.get_env(Keyword.get(unquote(opts), :otp_app), __MODULE__, [])

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

      # Expose channel properties so Node can be passed as an atom

      def host(), do: channel().host
      def port(), do: channel().port
      def scheme(), do: channel().scheme
      def cred(), do: channel().cred
      def adapter(), do: channel().adapter
      def adapter_payload(), do: channel().adapter_payload
      def codec(), do: channel().codec
      def interceptors(), do: channel().interceptors
      def compressor(), do: channel().compressor
      def accepted_compressors(), do: channel().accepted_compressors
      def headers(), do: channel().headers
    end
  end
end
