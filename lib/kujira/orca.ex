defmodule Kujira.Orca do
  @moduledoc """
  Methods for querying the Orca Liquidation Queues, and related data
  """

  alias GRPC.Channel
  alias Kujira.Contract
  alias Kujira.Orca.Queue

  @code_ids Application.get_env(:kujira, __MODULE__, code_ids: [108, 122, 216, 220])
            |> Keyword.get(:code_ids)

  @doc """
  Fetches the Queue contract and its current config from the chain
  """

  @spec get_queue(Channel.t(), String.t()) :: {:ok, Queue.t()} | {:error, :not_found}
  def get_queue(channel, address) do
    with {:ok, config} <- Contract.query_state_smart(channel, address, %{config: %{}}),
         {:ok, queue} <- Queue.from_config(address, config) do
      {:ok, queue}
    else
      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  Fetches all Liquidation Queues. This will only change when new Queues are deployed, so it is recommended to
  memoize this function with a manual flush
  """

  @spec list_queues(GRPC.Channel.t(), binary()) :: :error | {:ok, any()}
  def list_queues(channel, code_ids \\ @code_ids) do
    with {:ok, contracts} <- Contract.by_codes(channel, code_ids),
         {:ok, queues} <-
           contracts
           |> Task.async_stream(&get_queue(channel, &1))
           |> Enum.reduce({:ok, []}, fn
             {:ok, queue}, {:ok, queues} ->
               {:ok, [queue | queues]}

             _, err ->
               err
           end) do
      {:ok, queues}
    else
      _ ->
        :error
    end
  end

  @doc """
  Loads the current contract state into the Queue; the totals of each bid pool
  """

  @spec load_queue(Channel.t(), Queue.t()) :: {:ok, Queue.t()} | :error
  def load_queue(channel, queue) do
    with {:ok, %{"bid_pools" => bid_pools}} <-
           Contract.query_state_smart(channel, queue.address, %{bid_pools: %{limit: 30}}) do
      {:ok, Queue.load_pools(bid_pools, queue)}
    else
      _ ->
        :error
    end
  end
end
