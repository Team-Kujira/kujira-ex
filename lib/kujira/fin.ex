defmodule Kujira.Fin do
  @moduledoc """
  Kujira's 100% on-chain, central limit order book style decentralized token exchange.


  """

  alias Kujira.Contract
  alias Kujira.Fin.Pair
  alias Kujira.Fin.Book

  @pair_code_ids Application.get_env(:kujira, __MODULE__, pair_code_ids: [63, 134, 162])
                 |> Keyword.get(:pair_code_ids)

  @doc """
  Fetches the Pair contract and its current config from the chain.

  Config is very very rarely changed, if ever, and so this function is Memoized by default.
  Clear with `Memoize.invalidate(Kujira.Contract, :get, [{Pair, address}])`
  """

  @spec get_pair(Channel.t(), String.t()) :: {:ok, Pair.t()} | {:error, :not_found}
  def get_pair(channel, address), do: Contract.get(channel, {Pair, address})

  @doc """
  Fetches all Pairs. This will only change when config changes or new Pairs are added.
  It's Memoized, clearing every 24h.

  Manually clear with `Memoize.invalidate(Kujira.Contract, :list, [Vault, code_ids])`
  """

  @spec list_pairs(GRPC.Channel.t(), list(integer())) :: {:ok, list(Pair.t())} | :error
  def list_pairs(channel, code_ids \\ @pair_code_ids) when is_list(code_ids),
    do: Contract.list(channel, Pair, code_ids)

  @doc """
  Loads the current Book into the Pair. Default Memoization to ~ block time / 2 = 2s

  Manually clear with `Memoize.invalidate(Kujira.Fin, :load_pair, [pair, limit])`“
  """
  @spec load_pair(Channel.t(), Pair.t(), integer()) :: {:ok, Pair.t()} | :error
  def load_pair(channel, pair, limit \\ 100) do
    Memoize.Cache.get_or_run({__MODULE__, :get, [pair, limit]}, fn ->
      with {:ok, res} <-
             Contract.query_state_smart(channel, pair.address, %{book: %{}}),
           {:ok, book} <- Book.from_query(res) do
        {:ok, %{pair | book: book}}
      else
        _ ->
          :error
      end
    end)
  end
end
