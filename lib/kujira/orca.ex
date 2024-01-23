defmodule Kujira.Orca do
  @moduledoc """

  """

  alias GRPC.Channel
  alias Kujira.Contract
  alias Kujira.Orca.Queue

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
