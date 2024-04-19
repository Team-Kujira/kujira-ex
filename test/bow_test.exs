defmodule KujiraBowTest do
  alias Kujira.Bow
  use ExUnit.Case
  use Kujira.TestHelpers

  doctest Kujira.Bow

  test "fetches all leverage markets", %{channel: channel} do
    {:ok, contracts} = Bow.list_leverage(channel)
    [%Bow.Leverage{} | _] = contracts
    assert Enum.count(contracts) > 10
  end

  test "loads leverage market health", %{channel: channel} do
    {:ok, market} =
      Bow.get_leverage(
        channel,
        "kujira1vrwgc6j6ky6sk4a4x3axcm5fkddk88nqzrlsqkzsegledz58gm4su4exwx"
      )

    {:ok, health} = Bow.load_orca_market(channel, market)
  end
end
