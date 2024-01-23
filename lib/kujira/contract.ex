defmodule Kujira.Contract do
  @moduledoc """
  Documentation for `Kujira`.
  """

  @doc """
  Queries the full, raw contract state at an address. It's highly recommended to memoize any calls to this function,
  and invalidate them in response to external events e.g. a matching tx in a node websocket subscription

  ## Examples

      iex> Kujira.hello()
      :world

  """

  alias Cosmwasm.Wasm.V1.Query.Stub
  alias Cosmwasm.Wasm.V1.QuerySmartContractStateRequest

  def query_state_all do
    :world
  end

  @spec query_state_smart(GRPC.Channel.t(), String.t(), map()) ::
          {:ok, map()} | {:error, GRPC.RPCError.t()}
  def query_state_smart(channel, address, query) do
    with {:ok, %{data: data}} <-
           Stub.smart_contract_state(
             channel,
             QuerySmartContractStateRequest.new(
               address: address,
               query_data: Jason.encode!(query)
             )
           ),
         {:ok, res} <- Jason.decode(data) do
      {:ok, res}
    end
  end
end
