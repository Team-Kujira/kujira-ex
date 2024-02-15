defmodule KujiraOracleTest do
  alias Kujira.Oracle
  use ExUnit.Case
  use Kujira.TestHelpers

  doctest Kujira.Ghost

  test "queries all rates", %{channel: channel} do
    {:ok, %{"BTC" => _}} = Oracle.load_prices(channel)
  end
end
