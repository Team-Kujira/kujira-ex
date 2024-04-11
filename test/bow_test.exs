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
        "kujira1lrk6z5yxjaractukayphr5h45v8sh3j39u25qgrqxyz0hw9wzwtssggsuk"
      )

    {:ok, health} = Bow.load_orca_market(channel, market)
    IO.inspect(health)
  end
end
