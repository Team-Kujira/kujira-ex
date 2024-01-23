defmodule Kujira.Contract do
  @moduledoc """
  Convenience methods for querying CosmWasm smart contracts on Kujira
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
  alias Cosmwasm.Wasm.V1.QueryContractsByCodeRequest

  def query_state_all do
    :world
  end

  @spec by_code(GRPC.Channel.t(), String.t()) ::
          {:ok, list(String.t())} | {:error, GRPC.RPCError.t()}
  def by_code(channel, code_id) do
    with {:ok, %{contracts: contracts}} <-
           Stub.contracts_by_code(
             channel,
             QueryContractsByCodeRequest.new(code_id: code_id)
           ) do
      {:ok, contracts}
    end
  end

  @spec by_codes(GRPC.Channel.t(), String.t()) ::
          {:ok, list(String.t())} | {:error, GRPC.RPCError.t()}
  def by_codes(channel, code_ids) do
    Enum.reduce(code_ids, {:ok, []}, fn
      el, {:ok, agg} ->
        case by_code(channel, el) do
          {:ok, contracts} -> {:ok, agg ++ contracts}
          err -> err
        end

      _, err ->
        err
    end)
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
