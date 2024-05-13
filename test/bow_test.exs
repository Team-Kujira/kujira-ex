defmodule KujiraBowTest do
  alias Kujira.Bow.Leverage
  alias Kujira.Orca.Queue
  alias Kujira.Orca
  alias Kujira.Bow
  use ExUnit.Case
  use Kujira.TestHelpers

  doctest Kujira.Bow

  test "fetches a xyk pool", %{channel: channel} do
    {:ok, contract} =
      Bow.get_pool(channel, "kujira13t2d80s8a9lnzfzq4n6e0dde9n7ans50cuuv6t3ahh5cqudxvueql4ynp9")

    %Bow.Pool.Xyk{} = contract
  end

  test "fetches a stable pool", %{channel: channel} do
    {:ok, contract} =
      Bow.get_pool(channel, "kujira1l0dtky34pk0plaj5zxprs2zeg2977fh6ef4e4kpvu7695xqf4qeq9ztj6j")

    %Bow.Pool.Stable{} = contract
  end

  test "fetches an lsd contract adapter pool", %{channel: channel} do
    {:ok, contract} =
      Bow.get_pool(channel, "kujira1gel5fcfm4xknfd4j9m2d8smf3dm2jq75emu7n5g697la95d0ce8qqmxl59")

    %Bow.Pool.Lsd{adapter: %Bow.Pool.Lsd.Adapter.Contract{}} = contract
  end

  test "fetches an lsd oracle adapter pool", %{channel: channel} do
    {:ok, contract} =
      Bow.get_pool(channel, "kujira1lyyeyuw4qgan6nz45thw2m0nmxa457uz7cp9dqw5d9a0h7ccek7qavkm6g")

    %Bow.Pool.Lsd{adapter: %Bow.Pool.Lsd.Adapter.Oracle{}} = contract
  end

  test "fetches a legacy lsd pool", %{channel: channel} do
    {:ok, contract} =
      Bow.get_pool(channel, "kujira1776ux77z9juxf2x3mvt4hs2txauynkzngn4l6zc97jze59rykxuq7mgxjw")

    %Bow.Pool.Lsd{adapter: %{}} = contract
  end

  test "fetches all leverage markets", %{channel: channel} do
    {:ok, contracts} = Bow.list_leverage(channel)
    [%Bow.Leverage{} | _] = contracts
    assert Enum.count(contracts) > 10
  end

  test "loads leverage market health", %{channel: channel} do
    {:ok, contracts} = Bow.list_leverage(channel)

    for %{address: address} <- contracts do
      {:ok, market} = Bow.get_leverage(channel, address)

      {:ok,
       {%Orca.Market{address: {Leverage, market_a}, queue: {Queue, queue_a}},
        %Orca.Market{address: {Leverage, market_b}, queue: {Queue, queue_b}}}} =
        Bow.load_orca_markets(channel, market)

      assert queue_a != queue_b
      assert market_a == market_b
    end
  end
end
