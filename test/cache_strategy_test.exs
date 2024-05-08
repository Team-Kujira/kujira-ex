defmodule KujiraCacheStrategyTest do
  alias Kujira.CacheStrategy
  use ExUnit.Case
  use Kujira.TestHelpers

  # doctest Kujira.Coin

  test "caches an :ok value" do
    key = {__MODULE__, :test_cache, ["1"]}
    Memoize.Cache.get_or_run(key, fn -> {:ok, 42} end)

    [
      {key, {:completed, value, context}}
    ] = :ets.lookup(CacheStrategy.tab(key), key)

    :ok = CacheStrategy.read(key, value, context)
  end

  test "doesn't cache an :error response" do
    key = {__MODULE__, :test_cache, ["2"]}
    Memoize.Cache.get_or_run(key, fn -> {:error, :not_found} end)

    [] = :ets.lookup(CacheStrategy.tab(key), key)
  end
end
