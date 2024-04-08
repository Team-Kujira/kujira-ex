# Kujira

Elixir interfaces to Kujira dApps, for building indexers, APIs and bots

**N.B. This is currently a work in progress, as we begin to componentise & open source the infrastructure that powers the Kujira dApps**

## Installation

Add `kujira` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:kujira, "~> 0.1.21"}
  ]
end
```

## Connect to a node

Create a `MyApp.Node` module, configure the application's pubsub and [CometBFT subscriptions](https://docs.cometbft.com/v0.38/core/subscription)

```elixir
defmodule MyApp.Node do
  use Kujira.Node,
    otp_app: :my_app,
    pubsub: MyApp.PubSub,
    subscriptions: ["tm.event='NewBlock'"]
end

```

Configure the Node connection `config/*`

```elixir
config :my_app, MyApp.Node,
  host: "127.0.0.1",
  port: 9090,
  websocket: "wss://rpc-kujira.starsquid.io"
```

And start querying!

```elixir
defmodule MyAppWeb.PageController do
  alias Cosmos.Base.Tendermint
  use MyAppWeb, :controller
  import Tendermint.V1beta1.Service.Stub

  def index(conn, _params) do
    {:ok, %{block: block}} =
      get_latest_block(
        MyApp.Node.channel(),
        Tendermint.V1beta1.GetLatestBlockRequest.new()
      )

    conn |> assign(:block, block) |> render("index.html")
  end
end
```

CometBFT Events can be sunscribed to for realtime applications

```elixir
defmodule MyAppWeb.PageLive do
  use MyAppWeb, :live_view
  alias Cosmos.Base.Tendermint
  import Tendermint.V1beta1.Service.Stub
  alias Tendermint.V1beta1.GetLatestBlockRequest, as: LatestBlock
  alias Tendermint.V1beta1.GetBlockByHeightRequest, as: Block

  def mount(_params, _session, socket) do
    MyApp.Node.subscribe("tendermint/event/NewBlock")
    {:ok, %{block: block}} = get_latest_block(MyApp.Node.channel(), LatestBlock.new())

    {:ok, assign(socket, :block, block)}
  end

  def handle_info(%{block: %{header: %{height: height}}}, socket) do
    {:ok, %{block: block}} =
      get_block_by_height(
        MyApp.Node.channel(),
        Block.new(height: String.to_integer(height))
      )

    {:noreply, assign(socket, :block, block)}
  end
end

```

Docs can be found at <https://hexdocs.pm/kujira>.
