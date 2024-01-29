defmodule KujiraGhostTest do
  alias Kujira.Ghost
  use ExUnit.Case
  doctest Kujira.Ghost

  test "queries a vault" do
    {:ok, channel} =
      GRPC.Stub.connect("kujira-grpc.polkachu.com", 11890,
        interceptors: [{GRPC.Logger.Client, level: :debug}]
      )

    assert Ghost.get_vault(
             channel,
             #  Mainnet USK
             "kujira1w4yaama77v53fp0f9343t9w2f932z526vj970n2jv5055a7gt92sxgwypf"
           ) ==
             {:ok,
              %Ghost.Vault{
                address: "kujira1w4yaama77v53fp0f9343t9w2f932z526vj970n2jv5055a7gt92sxgwypf",
                debt_token: %Kujira.Token{
                  decimals: 6,
                  denom:
                    "factory/kujira1w4yaama77v53fp0f9343t9w2f932z526vj970n2jv5055a7gt92sxgwypf/udebt"
                },
                deposit_token: %Kujira.Token{
                  decimals: 6,
                  denom:
                    "factory/kujira1qk00h5atutpsv900x202pxx42npjr9thg58dnqpa72f2p7m2luase444a7/uusk"
                },
                markets: :not_loaded,
                oracle_denom: {:static, Decimal.new(1)},
                owner: "kujira1tsekaqv9vmem0zwskmf90gpf0twl6k57e8vdnq",
                receipt_token: %Kujira.Token{
                  decimals: 6,
                  denom:
                    "factory/kujira1w4yaama77v53fp0f9343t9w2f932z526vj970n2jv5055a7gt92sxgwypf/urcpt"
                }
              }}

    assert Ghost.get_vault(
             channel,
             #  Mainnet KUJI
             "kujira143fwcudwy0exd6zd3xyvqt2kae68ud6n8jqchufu7wdg5sryd4lqtlvvep"
           ) ==
             {:ok,
              %Kujira.Ghost.Vault{
                address: "kujira143fwcudwy0exd6zd3xyvqt2kae68ud6n8jqchufu7wdg5sryd4lqtlvvep",
                debt_token: %Kujira.Token{
                  decimals: 6,
                  denom:
                    "factory/kujira143fwcudwy0exd6zd3xyvqt2kae68ud6n8jqchufu7wdg5sryd4lqtlvvep/udebt"
                },
                deposit_token: %Kujira.Token{
                  decimals: 6,
                  denom: "ukuji"
                },
                markets: :not_loaded,
                oracle_denom: {:live, "KUJI"},
                owner: "kujira1tsekaqv9vmem0zwskmf90gpf0twl6k57e8vdnq",
                receipt_token: %Kujira.Token{
                  decimals: 6,
                  denom:
                    "factory/kujira143fwcudwy0exd6zd3xyvqt2kae68ud6n8jqchufu7wdg5sryd4lqtlvvep/urcpt"
                }
              }}
  end

  test "fetches all vaults" do
    {:ok, channel} =
      GRPC.Stub.connect("kujira-grpc.polkachu.com", 11890,
        interceptors: [{GRPC.Logger.Client, level: :debug}]
      )

    {:ok, vaults} = Ghost.list_vaults(channel)
    [%Ghost.Vault{} | _] = vaults
    assert Enum.count(vaults) > 10
  end

  test "queries a market" do
    {:ok, channel} =
      GRPC.Stub.connect("kujira-grpc.polkachu.com", 11890,
        interceptors: [{GRPC.Logger.Client, level: :debug}]
      )

    assert Ghost.get_market(
             channel,
             #  Mainnet KUJI-USK
             "kujira1aakur92cpmlygdcecruk5t8zjqtjnkf8fs8qlhhzuy5hkcrjddfs585grm"
           ) ==
             {:ok,
              %Kujira.Ghost.Market{
                address: "kujira1aakur92cpmlygdcecruk5t8zjqtjnkf8fs8qlhhzuy5hkcrjddfs585grm",
                borrow_fee: Decimal.new("0.002"),
                collateral_oracle_denom: "KUJI",
                collateral_token: %Kujira.Token{
                  decimals: 6,
                  denom: "ukuji"
                },
                full_liquidation_threshold: 1_000_000,
                max_ltv: Decimal.new("0.5"),
                orca_queue:
                  {Kujira.Orca.Queue,
                   "kujira1098ay2tx2238hwfmntjyfjms9zyqwlcdvmydyhq9d08lt8tj5mlss06myq"},
                owner: "kujira1tsekaqv9vmem0zwskmf90gpf0twl6k57e8vdnq",
                partial_liquidation_target: Decimal.new("0.4"),
                vault:
                  {Ghost.Vault,
                   "kujira1w4yaama77v53fp0f9343t9w2f932z526vj970n2jv5055a7gt92sxgwypf"},
                status: :not_loaded
              }}
  end

  test "loads a market status" do
    {:ok, channel} =
      GRPC.Stub.connect("kujira-grpc.polkachu.com", 11890,
        interceptors: [{GRPC.Logger.Client, level: :debug}]
      )

    {:ok, market} =
      Ghost.get_market(
        channel,
        #  Mainnet KUJI-USK
        "kujira1aakur92cpmlygdcecruk5t8zjqtjnkf8fs8qlhhzuy5hkcrjddfs585grm"
      )

    {:ok, market} = Ghost.load_market(channel, market)

    assert %Kujira.Ghost.Market{
             status: %Ghost.Market.Status{}
           } = market

    assert market.status.deposited > 0
    assert market.status.borrowed > 0
  end

  test "loads a market health" do
    {:ok, channel} =
      GRPC.Stub.connect("kujira-grpc.polkachu.com", 11890,
        interceptors: [{GRPC.Logger.Client, level: :debug}]
      )

    {:ok, market} =
      Ghost.get_market(
        channel,
        #  Mainnet KUJI-USK
        "kujira1aakur92cpmlygdcecruk5t8zjqtjnkf8fs8qlhhzuy5hkcrjddfs585grm"
      )

    {:ok, market} = Ghost.load_orca_market(channel, market)
  end

  test "fetches all markets" do
    {:ok, channel} =
      GRPC.Stub.connect("kujira-grpc.polkachu.com", 11890,
        interceptors: [{GRPC.Logger.Client, level: :debug}]
      )

    {:ok, markets} = Ghost.list_markets(channel)
    [%Ghost.Market{} | _] = markets
    assert Enum.count(markets) > 10
  end
end
