defmodule Kujira.Orca do
  @moduledoc """
  Methods for querying the Orca Liquidation Queues, and related data
  """

  alias GRPC.Channel
  alias Kujira.Contract
  alias Kujira.Orca.Bid
  alias Kujira.Orca.Queue
  use Memoize

  @code_ids Application.get_env(:kujira, __MODULE__, code_ids: [108, 122, 216, 220])
            |> Keyword.get(:code_ids)

  @doc """
  Fetches the Queue contract and its current config from the chain.

  Config is very very rarely changed, if ever, and so this function is Memoized forever by default.

  Manually clear with `Kujira.Orca.invalidate(:get_queue, address)`
  """

  @spec get_queue(Channel.t(), String.t()) :: {:ok, Queue.t()} | {:error, :not_found}
  def get_queue(channel, address), do: Contract.get(channel, {Queue, address})

  @doc """
  Fetches all Liquidation Queues. This will only change when config changes or new Queues are added.
  It's Memoized, clearing every 24h.

  Manually clear with `Kujira.Orca.invalidate(:list_queues)`
  """

  @spec list_queues(GRPC.Channel.t(), list(integer())) ::
          {:ok, list(Queue.t())} | {:error, GRPC.RPCError.t()}
  def list_queues(channel, code_ids \\ @code_ids) when is_list(code_ids),
    do: Contract.list(channel, Queue, code_ids)

  @doc """
  Loads the current contract state into the Queue; the totals of each bid pool. Default Memoization to ~ block time / 2 = 2s

  Manually clear with `Kujira.Orca.invalidate(:load_queue, queue)`
  """

  @spec load_queue(Channel.t(), Queue.t()) :: {:ok, Queue.t()} | {:error, GRPC.RPCError.t()}
  def load_queue(channel, queue) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :load_queue, [queue]},
      fn ->
        with {:ok, %{"bid_pools" => bid_pools}} <-
               Contract.query_state_smart(channel, queue.address, %{bid_pools: %{limit: 30}}) do
          {:ok, Queue.load_pools(bid_pools, queue)}
        else
          err -> err
        end
      end,
      expires_in: 2000
    )
  end

  @doc """
  Loads a bid for a specific Queue. Default Memoization to ~ block time / 2 = 2s

  Manually clear with `Kujira.Orca.invalidate(:load_bid, queue, idx)`
  """
  @spec load_bid(Channel.t(), Queue.t(), String.t()) ::
          {:ok, Bid.t()} | {:error, :not_found} | {:error, GRPC.RPCError.t()}
  def load_bid(channel, queue, idx) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :load_bid, [queue, idx]},
      fn ->
        with {:ok, bid} <-
               Contract.query_state_smart(channel, queue.address, %{bid: %{bid_idx: idx}}) do
          {:ok, Bid.from_query(queue, bid)}
        else
          {:error,
           %GRPC.RPCError{
             message:
               "codespace wasm code 9: query wasm contract failed: Generic error: No bids with the specified information exist",
             status: 2
           }} ->
            {:error, :not_found}

          err ->
            err
        end
      end,
      expires_in: 2000
    )
  end

  @doc """
  Loads a user's bids for a specific Queue. Default Memoization to ~ block time / 2 = 2s

  Manually clear with `Kujira.Orca.invalidate(:load_bids, queue, address)`
  """
  @spec load_bids(Channel.t(), Queue.t(), String.t()) ::
          {:ok, list(Bid.t())} | {:error, GRPC.RPCError.t()}
  def load_bids(channel, queue, address, start_after \\ nil) do
    Memoize.Cache.get_or_run(
      {__MODULE__, :load_bid, [queue, address, start_after]},
      fn ->
        with {:ok, %{"bids" => bids}} <-
               Contract.query_state_smart(channel, queue.address, %{
                 bids_by_user: %{bidder: address, start_after: start_after, limit: 30}
               }) do
          # TODO: Page through > 30
          bids = Enum.map(bids, &Bid.from_query(queue, &1))
          {:ok, bids}
        else
          err -> err
        end
      end,
      expires_in: 2000
    )
  end

  @doc """
  Creates a lazy stream for fetching all bids for a Queue
  """
  @spec stream_positions(GRPC.Channel.t(), Queue.t()) ::
          %Stream{}
  def stream_positions(channel, queue) do
    channel
    |> Contract.stream_state_all(queue.address)
    |> Stream.map(&Bid.from_query(queue, &1))
    |> Stream.filter(&(not is_nil(&1)))
  end

  def invalidate(:list_queues),
    do: Memoize.invalidate(Kujira.Contract, :list, [Queue, @code_ids])

  def invalidate(:get_queue, address),
    do: Memoize.invalidate(Kujira.Contract, :get, [{Queue, address}])

  def invalidate(:list_queues, code_ids),
    do: Memoize.invalidate(Kujira.Contract, :list, [Queue, code_ids])

  def invalidate(:load_queue, queue),
    do: Memoize.invalidate(__MODULE__, :load_queue, [queue, 100])

  def invalidate(:load_queue, queue, limit),
    do: Memoize.invalidate(__MODULE__, :load_queue, [queue, limit])

  def invalidate(:load_bid, queue, idx),
    do: Memoize.invalidate(__MODULE__, :load_bid, [queue, idx])

  def invalidate(:load_bids, queue, address),
    do: Memoize.invalidate(__MODULE__, :load_bids, [queue, address, nil])

  def invalidate(:load_bids, queue, address, start_after),
    do: Memoize.invalidate(__MODULE__, :load_bids, [queue, address, start_after])
end
