defmodule Kujira.Token do
  @moduledoc """
  Metadata for tokens on the Kujira Blockchain
  """

  use Memoize

  defstruct [:denom, :decimals, :trace, :meta]

  @type t :: %__MODULE__{
          denom: String.t(),
          decimals: integer(),
          trace: __MODULE__.Trace.t() | nil,
          meta: __MODULE__.Meta.t()
        }

  @doc """
  Fetches token information for a specific denom.
  Will fetch and cache the trace from the chain directly, then query and cache the chain-registry for
  all other token information
  """

  @spec from_denom(GRPC.Channel.t(), String.t()) ::
          {:ok, Kujira.Token.t()} | {:error, GRPC.RPCError.t()}
  def from_denom(%{"native" => denom}) do
    from_denom(denom)
  end

  def from_denom(channel, "ibc/" <> hash) do
    with {:ok, trace} <- __MODULE__.Trace.from_hash(channel, hash) do
      {:ok,
       %__MODULE__{denom: "ibc/#{hash}", decimals: 6, trace: trace}
       |> set_meta()}
    end
  end

  def from_denom(_, denom) do
    {:ok, %__MODULE__{denom: denom, decimals: 6, trace: nil} |> set_meta()}
  end

  # No trace, local asset
  def set_meta(token) do
    %{token | meta: __MODULE__.Meta.from_token(token)}
  end
end
