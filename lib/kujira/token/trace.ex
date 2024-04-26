defmodule Kujira.Token.Trace do
  @moduledoc """
  The IBC trace of a token
  """

  alias Ibc.Applications.Transfer.V1.QueryDenomTraceRequest
  import Ibc.Applications.Transfer.V1.Query.Stub
  use Memoize

  defstruct [:base_denom, :path]

  @type t :: %__MODULE__{base_denom: String.t(), path: String.t()}

  defmemo from_hash(channel, hash) do
    with {:ok, %{denom_trace: trace}} <-
           denom_trace(channel, QueryDenomTraceRequest.new(hash: hash)) do
      {:ok, %__MODULE__{base_denom: trace.base_denom, path: trace.path}}
    end
  end
end
