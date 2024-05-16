defmodule Kujira.Fin do
  @moduledoc """
  Kujira's 100% on-chain, central limit order book style decentralized token exchange.
  """

  alias Kujira.Contract
  alias Kujira.Fin.Pair
  alias Kujira.Fin.Book

  @pair_code_ids Application.compile_env(:kujira, __MODULE__, pair_code_ids: [283])
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
      {__MODULE__, :load_pair, [pair, limit]},
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
end
