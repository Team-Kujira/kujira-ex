defmodule Kujira.Token.Meta do
  @moduledoc """
  Metadata for a token
  """

  alias Kujira.Token

  defstruct [:name, :symbol, :coingecko_id, :png, :svg]

  @type t ::
          %__MODULE__{
            name: String.t(),
            symbol: String.t(),
            coingecko_id: String.t() | nil,
            png: String.t() | nil,
            svg: String.t() | nil
          }
          | {:error, :not_found}
          # If the token is an IBC token with multiple hops, we don't try and trace it back
          | {:error, :indirect}

  # Local token, fetch from kujira assetlist
  @spec from_token(Kujira.Token.t()) :: Kujira.Token.Meta.t()
  def from_token(%Token{denom: denom, trace: nil}) do
    with {:ok, res} <- ChainRegistry.chain_assets("kujira"),
         %{"name" => name, "symbol" => symbol} = item <-
           res
           |> Map.get("assets")
           |> Enum.find(&(&1["base"] == denom)) do
      %__MODULE__{
        name: name,
        symbol: symbol,
        coingecko_id: Map.get(item, "coingecko_id", nil),
        png: item |> Map.get("images", []) |> Enum.at(0, %{}) |> Map.get("png", nil),
        svg: item |> Map.get("images", []) |> Enum.at(0, %{}) |> Map.get("svg", nil)
      }
    end
  end

  # Local token, fetch from kujira assetlist
  @spec from_token(Kujira.Token.t()) :: Kujira.Token.Meta.t()
  def from_token(%Token{denom: _, trace: _}) do
    %__MODULE__{}
  end
end
