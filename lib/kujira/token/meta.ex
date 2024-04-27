defmodule Kujira.Token.Meta do
  @moduledoc """
  Metadata for a token
  """

  use Memoize
  import Ibc.Core.Channel.V1.Query.Stub
  alias Ibc.Core.Channel.V1.QueryChannelClientStateRequest
  alias Ibc.Lightclients.Tendermint.V1.ClientState

  alias Kujira.Token

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
          | {:error, :not_found}
          # If the token is an IBC token with multiple hops, we don't try and trace it back
          | {:error, :indirect}

  # Local token, fetch from kujira assetlist
  @spec from_token(GRPC.Channel.t(), Kujira.Token.t()) :: Kujira.Token.Meta.t()
  def from_token(_, %Token{denom: denom, trace: nil}) do
    with {:ok, res} <- ChainRegistry.chain_assets("kujira"),
         %{"name" => name, "symbol" => symbol, "denom_units" => [_, %{"exponent" => decimals}]} =
           item <-
           res
           |> Map.get("assets")
           |> Enum.find(&(&1["base"] == denom)) do
      {:ok,
       %__MODULE__{
         name: name,
         decimals: decimals,
         symbol: symbol,
         coingecko_id: Map.get(item, "coingecko_id", nil),
         png: item |> Map.get("images", []) |> Enum.at(0, %{}) |> Map.get("png", nil),
         svg: item |> Map.get("images", []) |> Enum.at(0, %{}) |> Map.get("svg", nil)
       }}
    end
  end

  # Local token, fetch from kujira assetlist
  @spec from_token(GRPC.Channel.t(), Kujira.Token.t()) :: Kujira.Token.Meta.t()
  def from_token(channel, %Token{
        denom: _,
        trace: %{path: "transfer/" <> trace, base_denom: denom}
      }) do
    [channel_id | _] = String.split(trace, "/")

    with {:ok, chain_id} = get_counterparty_chain_id(channel, channel_id),
         {:ok, chain_name} <- CosmosDirectory.chain_name(chain_id),
         {:ok, res} <- ChainRegistry.chain_assets(chain_name),
         %{"name" => name, "symbol" => symbol, "denom_units" => [_, %{"exponent" => decimals}]} =
           item <-
           res
           |> Map.get("assets")
           |> Enum.find(&(&1["base"] == denom)) do
      {:ok,
       %__MODULE__{
         name: name,
         decimals: decimals,
         symbol: symbol,
         coingecko_id: Map.get(item, "coingecko_id", nil),
         png: item |> Map.get("images", []) |> Enum.at(0, %{}) |> Map.get("png", nil),
         svg: item |> Map.get("images", []) |> Enum.at(0, %{}) |> Map.get("svg", nil)
       }}
    end
  end

  defmemop get_counterparty_chain_id(channel, channel_id) do
    with {:ok, %{identified_client_state: %{client_state: client_state}}} <-
           channel_client_state(
             channel,
             QueryChannelClientStateRequest.new(port_id: "transfer", channel_id: channel_id)
           ),
         %ClientState{chain_id: chain_id} <- Kujira.decode(client_state) do
      {:ok, chain_id}
    end
  end
end
