defmodule Kujira.Fin do
  @moduledoc """
  Kujira's 100% on-chain, central limit order book style decentralized token exchange.


  """

  alias Kujira.Contract
  alias Kujira.Fin.Pair
  alias Kujira.Fin.Book

  @pair_code_ids Application.get_env(:kujira, __MODULE__, pair_code_ids: [283])
                 |> Keyword.get(:pair_code_ids)

  @doc """
  Fetches the Pair contract and its current config from the chain.

  Config is very very rarely changed, if ever, and so this function is Memoized by default.

  Manually clear with `Kujira.Fin.invalidate(:get_pair, address)`
  """

  @spec get_pair(Channel.t(), String.t()) :: {:ok, Pair.t()} | {:error, :not_found}
  def get_pair(channel, address), do: Contract.get(channel, {Pair, address})

  @doc """
  Fetches all Pairs. This will only change when config changes or new Pairs are added.
  It's Memoized, clearing every 24h.

  Manually clear with `Kujira.Fin.invalidate(:list_pairs)`
  """

  @spec list_pairs(GRPC.Channel.t(), list(integer())) ::
          {:ok, list(Pair.t())} | {:error, GRPC.RPCError.t()}
  def list_pairs(channel, code_ids \\ @pair_code_ids) when is_list(code_ids),
    do: Contract.list(channel, Pair, code_ids)

  @doc """
  Loads the current Book into the Pair. Default Memoization to ~ block time / 2 = 2s

  Manually clear with `Kujira.Fin.invalidate(:load_pair, address)`
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
      end,
      expires_in: 2000
    )
  end

  def invalidate(:list_pairs),
    do: Memoize.invalidate(Kujira.Contract, :list, [Pair, @pair_code_ids])

  def invalidate(:get_pair, address),
    do: Memoize.invalidate(Kujira.Contract, :get, [{Pair, address}])

  def invalidate(:list_pairs, code_ids),
    do: Memoize.invalidate(Kujira.Contract, :list, [Pair, code_ids])

  def invalidate(:load_pair, pair),
    do: Memoize.invalidate(__MODULE__, :load_pair, [pair, 100])

  def invalidate(:load_pair, pair, limit),
    do: Memoize.invalidate(__MODULE__, :load_pair, [pair, limit])
end
