defmodule KujiraFinTest do
  alias Kujira.Fin
  use ExUnit.Case
  use Kujira.TestHelpers

  # doctest Kujira.Fin

  test "fetches all pairs", %{channel: channel} do
    {:ok, pairs} = Fin.list_pairs(channel)
    [%Fin.Pair{} | _] = pairs
    assert Enum.count(pairs) > 100
  end

  test "fetches orders", %{channel: channel} do
    {:ok, pair} =
      Fin.get_pair(channel, "kujira1a0fyanyqm496fpgneqawhlsug6uqfvqg2epnw39q0jdenw3zs8zqsjhdr0")

    {:ok, orders} =
      Fin.list_orders(channel, pair, "kujira1xe0awk5planmtsmjel5xtx2hzhqdw5p8z66yqd")

    [
      %Fin.Order{
        created_at: ~U[2023-05-03 11:39:23.784292Z],
        filled_amount: 0,
        id: "35498",
        offer_token: %Kujira.Token{
          denom: "ibc/DADB399E742FCEE71853E98225D13E44E90292852CD0033DF5CABAB96F80B833"
        },
        owner: "kujira1xe0awk5planmtsmjel5xtx2hzhqdw5p8z66yqd",
        pair:
          {Kujira.Fin.Pair, "kujira1a0fyanyqm496fpgneqawhlsug6uqfvqg2epnw39q0jdenw3zs8zqsjhdr0"}
      }
    ] = orders
  end
end
