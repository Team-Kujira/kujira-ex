defmodule KujiraOrcaTest do
  alias Kujira.Orca
  use ExUnit.Case
  use Kujira.TestHelpers

  doctest Kujira.Orca

  test "queries a queue", %{channel: channel} do
    assert Kujira.Orca.get_queue(
             channel,
             #  Mainnet KUJI - xUSK
             "kujira1098ay2tx2238hwfmntjyfjms9zyqwlcdvmydyhq9d08lt8tj5mlss06myq"
           ) ==
             {:ok,
              %Kujira.Orca.Queue{
                activation_delay: 600,
                activation_threshold: 10_000_000_000,
                address: "kujira1098ay2tx2238hwfmntjyfjms9zyqwlcdvmydyhq9d08lt8tj5mlss06myq",
                bid_pools: [
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.00"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.01"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.02"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.03"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.04"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.05"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.06"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.07"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.08"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.09"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.10"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.11"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.12"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.13"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.14"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.15"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.16"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.17"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.18"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.19"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.20"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.21"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.22"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.23"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.24"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.25"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.26"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.27"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.28"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.29"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  },
                  %Kujira.Orca.Pool{
                    premium: Decimal.new("0.30"),
                    total: :not_loaded,
                    epoch: :not_loaded
                  }
                ],
                bid_token: %Kujira.Token{
                  decimals: 6,
                  denom:
                    "factory/kujira1w4yaama77v53fp0f9343t9w2f932z526vj970n2jv5055a7gt92sxgwypf/urcpt"
                },
                collateral_token: %Kujira.Token{
                  decimals: 6,
                  denom: "ukuji"
                },
                liquidation_fee: Decimal.new("0.01"),
                owner: "kujira1tsekaqv9vmem0zwskmf90gpf0twl6k57e8vdnq",
                withdrawal_fee: Decimal.new("0.005")
              }}
  end

  test "populates a queue", %{channel: channel} do
    {:ok, queue} =
      Kujira.Orca.get_queue(
        channel,
        #  Mainnet KUJI - xUSK
        "kujira1098ay2tx2238hwfmntjyfjms9zyqwlcdvmydyhq9d08lt8tj5mlss06myq"
      )

    {:ok, queue} = Kujira.Orca.load_queue(channel, queue)

    for pool <- queue.bid_pools do
      assert is_integer(pool.total)
      assert is_integer(pool.epoch)
    end
  end

  test "fetches all queues", %{channel: channel} do
    {:ok, queues} = Kujira.Orca.list_queues(channel)
    [%Kujira.Orca.Queue{} | _] = queues
    assert Enum.count(queues) > 10
  end

  test "extracts a liquidation from a transaction", %{channel: channel} do
    %{tx_response: response} =
      load_tx("E9262E61B7AB1E38F87AEFDDC895DDE62D398AAB3266FDEE7CE9D8893BAAED91")

    liquidations = Orca.Liquidation.from_tx_response(response)

    assert liquidations == [
             %Orca.Liquidation{
               bid_amount: 427_683_367,
               collateral_amount: 432_068_606_295_908_982_392,
               fee_amount: 4_276_832,
               height: 18_498_905,
               market_address:
                 "kujira1wgxks9jwla3q6axpk0vjg89ujvet9t94dd0xtqueqjx59g46e4zq4mvd9a",
               queue_address: "kujira1hdm7rw8t9903t5etqc6mpce3q5dslqqhczznvkz5xr4rzrq72gpqwkxlws",
               repay_amount: 423_406_534,
               timestamp: ~U[2024-04-19 02:23:51Z],
               txhash: "E9262E61B7AB1E38F87AEFDDC895DDE62D398AAB3266FDEE7CE9D8893BAAED91"
             }
           ]
  end

  test "queries a bid", %{channel: channel} do
    {:ok, queue} =
      Kujira.Orca.get_queue(
        channel,
        #  Mainnet ATOM - USK
        "kujira1q8y46xg993cqg3xjycyw2334tepey7dmnh5jk2psutrz3fc69teskctgfc"
      )

    {:error, :not_found} = Kujira.Orca.load_bid(channel, queue, "1")

    {:ok, bid} = Kujira.Orca.load_bid(channel, queue, "9434")

    assert bid == %Kujira.Orca.Bid{
             activation_time: ~U[2024-04-19 11:13:26Z],
             bid_amount: 10000,
             bidder: "kujira1gee7m7kygxuc4xk483ceuqcfczv48ygt27xgwk",
             delegate: nil,
             filled_amount: 0,
             id: "9434",
             premium: Decimal.new("0.30")
           }
  end

  test "queries a user's bids", %{channel: channel} do
    {:ok, queue} =
      Kujira.Orca.get_queue(
        channel,
        #  Mainnet ATOM - USK
        "kujira1q8y46xg993cqg3xjycyw2334tepey7dmnh5jk2psutrz3fc69teskctgfc"
      )

    {:ok, bids} =
      Kujira.Orca.load_bids(channel, queue, "kujira1gee7m7kygxuc4xk483ceuqcfczv48ygt27xgwk")

    assert bids == [
             %Kujira.Orca.Bid{
               activation_time: ~U[2024-04-19 11:13:26Z],
               bid_amount: 10000,
               bidder: "kujira1gee7m7kygxuc4xk483ceuqcfczv48ygt27xgwk",
               delegate: nil,
               filled_amount: 0,
               id: "9434",
               premium: Decimal.new("0.30")
             }
           ]
  end

  test "extracts a new bid from a transaction", %{channel: channel} do
    %{tx_response: response} =
      load_tx("B6D8161EAEA1639E5CF5DB3BB04481B63BA254A31726F2A171401D1482392071")

    bids = Orca.Bid.from_tx_response(channel, response)

    assert bids ==
             [
               {"kujira1sdlp8eqp4md6waqv2x9vlvt9dtzyx9ztt0zvkfxaw9kxh3t5gdvqypxlwz",
                %Kujira.Orca.Bid{
                  activation_time: :not_loaded,
                  bid_amount: 4_478_381,
                  bidder: "kujira15ursa2ykyryvdqjafyuu4spntex3us7m22lpzp",
                  delegate: nil,
                  filled_amount: 0,
                  id: "2393",
                  premium: Decimal.new("0.15")
                }}
             ]
  end
end
