defmodule Kujira.Token.Meta do
  defmodule Error do
    defstruct [:error]

    @type t :: %__MODULE__{
            error:
              :denom_unit_not_found
              | :chain_registry_entry_not_found
              # If the token is an IBC token with multiple hops, we don't try and trace it back
              | :indirect
          }

    def new(error), do: %__MODULE__{error: error}
  end

  @moduledoc """
  Metadata for a token
  """

  use Memoize
  import Ibc.Core.Channel.V1.Query.Stub
  alias Kujira.Ghost
  alias Ibc.Core.Channel.V1.QueryChannelClientStateRequest
  alias Ibc.Lightclients.Tendermint.V1.ClientState

  alias Kujira.Token

  @custom [Ghost]

  defstruct [:name, :decimals, :symbol, :coingecko_id, :png, :svg]

  @type t ::
          %__MODULE__{
            name: String.t(),
            decimals: non_neg_integer(),
            symbol: String.t(),
            coingecko_id: String.t() | nil,
            png: String.t() | nil,
            svg: String.t() | nil
          }
          | __MODULE__.Error.t()

  # Local token, fetch from kujira assetlist
  @spec from_token(GRPC.Channel.t(), Kujira.Token.t()) :: {:ok, Kujira.Token.Meta.t()}
  def from_token(channel, %Token{denom: denom, trace: nil}) do
    case Enum.reduce(@custom, nil, fn v, _ ->
           v.token_meta(channel, %Token{denom: denom, trace: nil})
         end) do
      nil ->
        with {:ok, res} <- ChainRegistry.chain_assets("kujira") do
          res
          |> Map.get("assets", [])
          |> Enum.find(&(&1["base"] == denom))
          |> from_chain_registry()
        end

      %__MODULE__{} = meta ->
        {:ok, meta}
    end
  end

  # Local token, fetch from kujira assetlist
  def from_token(channel, %Token{
        denom: _,
        trace: %{path: "transfer/" <> trace, base_denom: denom}
      }) do
    [channel_id | _] = String.split(trace, "/")

    with {:ok, chain_id} = get_counterparty_chain_id(channel, channel_id),
         {:ok, chain_name} <- CosmosDirectory.chain_name(chain_id),
         {:ok, res} <- ChainRegistry.chain_assets(chain_name) do
      res
      |> Map.get("assets")
      |> Enum.find(&(&1["base"] == denom))
      |> from_chain_registry()
    end
  end

  defp from_chain_registry(
         %{
           "name" => name,
           "symbol" => symbol,
           "denom_units" => denom_units,
           "display" => display
         } = item
       ) do
    with %{"exponent" => decimals} <-
           Enum.find(denom_units, &(&1["denom"] == display)) do
      {:ok,
       %__MODULE__{
         name: name,
         decimals: decimals,
         symbol: symbol,
         coingecko_id: Map.get(item, "coingecko_id", nil),
         png: item |> Map.get("images", []) |> Enum.at(0, %{}) |> Map.get("png", nil),
         svg: item |> Map.get("images", []) |> Enum.at(0, %{}) |> Map.get("svg", nil)
       }}
    else
      nil ->
        {:ok, __MODULE__.Error.new(:denom_unit_not_found)}
    end
  end

  defp from_chain_registry(nil) do
    {:ok, __MODULE__.Error.new(:chain_registry_entry_not_found)}
  end

  defp get_counterparty_chain_id(channel, channel_id) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :get_counterparty_chain_id, [channel_id]},
      fn ->
        with {:ok, %{identified_client_state: %{client_state: client_state}}} <-
               channel_client_state(
                 channel,
                 QueryChannelClientStateRequest.new(port_id: "transfer", channel_id: channel_id)
               ),
             %ClientState{chain_id: chain_id} <- Kujira.decode_any(client_state) do
          {:ok, chain_id}
        end
      end
    )
  end
end
