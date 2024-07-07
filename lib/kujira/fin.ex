defmodule Kujira.Fin do
  @moduledoc """
  Kujira's 100% on-chain, central limit order book style decentralized token exchange.
  """

  alias Kujira.Fin.Order
  alias Kujira.Contract
  alias Kujira.Fin.Pair
  alias Kujira.Fin.Book

  @pair_code_ids Application.compile_env(:kujira, __MODULE__, pair_code_ids: [283, 352])
                 |> Keyword.get(:pair_code_ids)

  @doc """
  Fetches the Pair contract and its current config from the chain
  """

  @spec get_pair(Channel.t(), String.t()) :: {:ok, Pair.t()} | {:error, :not_found}
  def get_pair(channel, address), do: Contract.get(channel, {Pair, address})

  @doc """
  Fetches all Pairs
  """

  @spec list_pairs(GRPC.Channel.t(), list(integer())) ::
          {:ok, list(Pair.t())} | {:error, GRPC.RPCError.t()}
  def list_pairs(channel, code_ids \\ @pair_code_ids) when is_list(code_ids),
    do: Contract.list(channel, Pair, code_ids)

  @doc """
  Loads the current Book into the Pair
  """
  @spec load_pair(Channel.t(), Pair.t(), integer()) ::
          {:ok, Pair.t()} | {:error, GRPC.RPCError.t()}
  def load_pair(channel, pair, limit \\ 100) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :load_pair, [pair.address]},
      fn ->
        with {:ok, res} <-
               Contract.query_state_smart(channel, pair.address, %{book: %{limit: limit}}),
             {:ok, book} <- Book.from_query(res) do
          {:ok, %{pair | book: book}}
        else
          err ->
            err
        end
      end
    )
  end

  @doc """
  Fetches all Orders for a pair
  """

  @spec list_orders(GRPC.Channel.t(), Pair.t(), String.t()) ::
          {:ok, list(Order.t())} | {:error, GRPC.RPCError.t()}
  def list_orders(channel, pair, address) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :list_orders, [pair.address, address]},
      fn ->
        with {:ok, %{"orders" => orders}} <-
               Contract.query_state_smart(channel, pair.address, %{
                 orders_by_user: %{address: address}
               }) do
          {:ok, Enum.map(orders, &Order.from_query(channel, pair, &1))}
        else
          err ->
            err
        end
      end
    )
  end
end
