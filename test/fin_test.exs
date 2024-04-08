defmodule KujiraFinTest do
  alias Kujira.Fin
  use ExUnit.Case
  use Kujira.TestHelpers

  doctest Kujira.Fin

  test "fetches all pairs", %{channel: channel} do
    {:ok, pairs} = Fin.list_pairs(channel)
    [%Fin.Pair{} | _] = pairs
    assert Enum.count(pairs) > 10
  end
end
