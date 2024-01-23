defmodule KujiraOrcaTest do
  use ExUnit.Case
  doctest Kujira.Orca

  test "queries a queue" do
    {:ok, channel} =
      GRPC.Stub.connect("kujira-grpc.polkachu.com", 11890,
        interceptors: [{GRPC.Logger.Client, level: :debug}]
      )

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

  test "populates a queue" do
    {:ok, channel} =
      GRPC.Stub.connect("kujira-grpc.polkachu.com", 11890,
        interceptors: [{GRPC.Logger.Client, level: :debug}]
      )

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
end
