defmodule Kujira.Contract do
  @moduledoc """
  Convenience methods for querying CosmWasm smart contracts on Kujira
  """

  @doc """
  Queries the full, raw contract state at an address. It's highly recommended to memoize any calls to this function,
  and invalidate them in response to external events e.g. a matching tx in a node websocket subscription
  """

  alias Cosmwasm.Wasm.V1.Query.Stub
  alias Cosmwasm.Wasm.V1.QuerySmartContractStateRequest
  alias Cosmwasm.Wasm.V1.QueryContractsByCodeRequest

  def query_state_all do
    :world
  end

  @spec by_code(GRPC.Channel.t(), integer()) ::
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

  @spec by_codes(GRPC.Channel.t(), list(integer())) ::
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

  @spec get(Channel.t(), {module(), String.t()}) :: {:ok, struct()} | {:error, :not_found}
  def get(channel, {module, address}) do
    Memoize.Cache.get_or_run({__MODULE__, :resolve, [address]}, fn ->
      with {:ok, config} <- query_state_smart(channel, address, %{config: %{}}),
           {:ok, struct} <- module.from_config(address, config) do
        {:ok, struct}
      else
        _ ->
          {:error, :not_found}
      end
    end)
  end

  @spec list(GRPC.Channel.t(), module(), list(integer())) :: {:ok, list(struct())} | :error
  def list(channel, module, code_ids) when is_list(code_ids) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :resolve, [code_ids]},
      fn ->
        with {:ok, contracts} <- by_codes(channel, code_ids),
             {:ok, struct} <-
               contracts
               |> Task.async_stream(&get(channel, {module, &1}))
               |> Enum.reduce({:ok, []}, fn
                 {:ok, {:ok, x}}, {:ok, xs} ->
                   {:ok, [x | xs]}

                 _, err ->
                   err
               end) do
          {:ok, struct}
        else
          _ ->
            :error
        end
      end,
      expires_in: 24 * 60 * 1000
    )
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
