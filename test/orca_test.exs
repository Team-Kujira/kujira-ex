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
    {:ok, %{tx_response: response}} =
      Cosmos.Tx.V1beta1.Service.Stub.get_tx(channel, %Cosmos.Tx.V1beta1.GetTxRequest{
        # TODO: Mock transaction responses as they'll eventually be pruned from gRPC nodes
        hash: "BC02D586A26C5FBA1B95F79332316BFE58E037E7FD94CE2E377011FC1BDBD4CD"
      })

    liquidations = Orca.Liquidation.from_tx_response(response)

    assert liquidations == [
             %Orca.Liquidation{
               bid_amount: 4_100_551_365,
               collateral_amount: 6_400_000_000_014_715_799_261,
               fee_amount: 41_005_512,
               height: 16_840_386,
               market_address:
                 "kujira1zc3a6ncr4lajr9du6chuxwef34l8ppj9h8x0yc3fslkk82da9m2sajlmv2",
               queue_address: "kujira1nt76mfz0jx9dzz6mgxd2hvxwzs9tjkn9sm335mrx66zc4xx7mh5qpr8v2v",
               repay_amount: 4_059_545_852,
               timestamp: ~U[2024-01-23T14:10:54Z],
               txhash: "BC02D586A26C5FBA1B95F79332316BFE58E037E7FD94CE2E377011FC1BDBD4CD"
             }
           ]
  end

  test "queries a bid", %{channel: channel} do
    {:ok, queue} =
      Kujira.Orca.get_queue(
        channel,
        #  Mainnet LUNA - USK
        "kujira1sdlp8eqp4md6waqv2x9vlvt9dtzyx9ztt0zvkfxaw9kxh3t5gdvqypxlwz"
      )

    {:error, :not_found} = Kujira.Orca.load_bid(channel, queue, "1")

    {:ok, bid} = Kujira.Orca.load_bid(channel, queue, "2252")

    assert bid == %Kujira.Orca.Bid{
             activation_time: nil,
             bid_amount: 4_088_981,
             bidder: "kujira1ltvwg69sw3c5z99c6rr08hal7v0kdzfxz07yj5",
             delegate: nil,
             filled_amount: 0,
             id: "2252",
             premium: Decimal.new("0.15")
           }
  end

  test "queries a user's bids", %{channel: channel} do
    {:ok, queue} =
      Kujira.Orca.get_queue(
        channel,
        #  Mainnet LUNA - USK
        "kujira1sdlp8eqp4md6waqv2x9vlvt9dtzyx9ztt0zvkfxaw9kxh3t5gdvqypxlwz"
      )

    {:ok, bids} =
      Kujira.Orca.load_bids(channel, queue, "kujira1ltvwg69sw3c5z99c6rr08hal7v0kdzfxz07yj5")

    assert bids == [
             %Kujira.Orca.Bid{
               activation_time: nil,
               bid_amount: 4_088_981,
               bidder: "kujira1ltvwg69sw3c5z99c6rr08hal7v0kdzfxz07yj5",
               delegate: nil,
               filled_amount: 0,
               id: "2252",
               premium: Decimal.new("0.15")
             }
           ]
  end

  test "extracts a new bid from a transaction", %{channel: channel} do
    {:ok, %{tx_response: response}} =
      Cosmos.Tx.V1beta1.Service.Stub.get_tx(channel, %Cosmos.Tx.V1beta1.GetTxRequest{
        # TODO: Mock transaction responses as they'll eventually be pruned from gRPC nodes
        hash: "968B00A8A38B4FE26694B2C5B8AEEB50437E13A916103AFB2DC3A7529B1AA212"
      })

    bids = Orca.Bid.from_tx_response(channel, response)

    assert bids ==
             [
               {"kujira1zkh4y25snp78qt6zauucklw7wuudss2n5vuya7p79uah922uwudqmw6r8a",
                %Kujira.Orca.Bid{
                  activation_time: :not_loaded,
                  bid_amount: 989_344_412,
                  bidder: "kujira1el4z7lxhq970vdcyhk24lvaus58d5ghazgqmfk",
                  filled_amount: 0,
                  id: "158",
                  premium: Decimal.new("0.030")
                }}
             ]
  end
end
