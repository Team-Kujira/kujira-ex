defmodule KujiraGhostTest do
  alias Kujira.Ghost.Position
  alias Kujira.Ghost
  use ExUnit.Case
  use Kujira.TestHelpers

  doctest Kujira.Ghost

  test "queries a vault", %{channel: channel} do
    assert Ghost.get_vault(
             channel,
             #  Mainnet USK
             "kujira1w4yaama77v53fp0f9343t9w2f932z526vj970n2jv5055a7gt92sxgwypf"
           ) ==
             {:ok,
              %Ghost.Vault{
                address: "kujira1w4yaama77v53fp0f9343t9w2f932z526vj970n2jv5055a7gt92sxgwypf",
                debt_token: %Kujira.Token{
                  denom:
                    "factory/kujira1w4yaama77v53fp0f9343t9w2f932z526vj970n2jv5055a7gt92sxgwypf/udebt",
                  meta: %Kujira.Token.Meta.Error{message: :chain_registry_entry_not_found},
                  trace: nil
                },
                deposit_token: %Kujira.Token{
                  denom:
                    "factory/kujira1qk00h5atutpsv900x202pxx42npjr9thg58dnqpa72f2p7m2luase444a7/uusk",
                  meta: %Kujira.Token.Meta{
                    coingecko_id: "usk",
                    decimals: 6,
                    name: "USK",
                    png:
                      "https://raw.githubusercontent.com/cosmos/chain-registry/master/kujira/images/usk.png",
                    svg:
                      "https://raw.githubusercontent.com/cosmos/chain-registry/master/kujira/images/usk.svg",
                    symbol: "USK"
                  },
                  trace: nil
                },
                markets: :not_loaded,
                oracle_denom: {:static, Decimal.new("1")},
                owner: "kujira1tsekaqv9vmem0zwskmf90gpf0twl6k57e8vdnq",
                receipt_token: %Kujira.Token{
                  denom:
                    "factory/kujira1w4yaama77v53fp0f9343t9w2f932z526vj970n2jv5055a7gt92sxgwypf/urcpt",
                  meta: %Kujira.Token.Meta{
                    coingecko_id: nil,
                    decimals: 6,
                    name: "Ghost Vault USK",
                    png:
                      "https://raw.githubusercontent.com/cosmos/chain-registry/master/kujira/images/xusk.png",
                    svg: nil,
                    symbol: "xUSK"
                  },
                  trace: nil
                },
                status: :not_loaded
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
                  denom:
                    "factory/kujira143fwcudwy0exd6zd3xyvqt2kae68ud6n8jqchufu7wdg5sryd4lqtlvvep/udebt",
                  meta: %Kujira.Token.Meta.Error{message: :chain_registry_entry_not_found},
                  trace: nil
                },
                deposit_token: %Kujira.Token{
                  denom: "ukuji",
                  meta: %Kujira.Token.Meta{
                    coingecko_id: "kujira",
                    decimals: 6,
                    name: "Kujira",
                    png:
                      "https://raw.githubusercontent.com/cosmos/chain-registry/master/kujira/images/kuji.png",
                    svg:
                      "https://raw.githubusercontent.com/cosmos/chain-registry/master/kujira/images/kuji.svg",
                    symbol: "KUJI"
                  },
                  trace: nil
                },
                markets: :not_loaded,
                oracle_denom: {:live, "KUJI"},
                owner: "kujira1tsekaqv9vmem0zwskmf90gpf0twl6k57e8vdnq",
                receipt_token: %Kujira.Token{
                  denom:
                    "factory/kujira143fwcudwy0exd6zd3xyvqt2kae68ud6n8jqchufu7wdg5sryd4lqtlvvep/urcpt",
                  meta: %Kujira.Token.Meta.Error{
                    message: :chain_registry_entry_not_found
                  }
                  # meta: %Kujira.Token.Meta{
                  #   coingecko_id: nil,
                  #   decimals: 6,
                  #   name: "Ghost Vault KUJI",
                  #   png:
                  #     "https://raw.githubusercontent.com/cosmos/chain-registry/master/kujira/images/xkuji.png",
                  #   svg: nil,
                  #   symbol: "xKUJI"
                  # }
                },
                status: :not_loaded
              }}
  end

  test "fetches all vaults", %{channel: channel} do
    {:ok, vaults} = Ghost.list_vaults(channel)
    [%Ghost.Vault{} | _] = vaults
    assert Enum.count(vaults) > 10
  end

  test "queries a market", %{channel: channel} do
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
                  denom: "ukuji",
                  meta: %Kujira.Token.Meta{
                    coingecko_id: "kujira",
                    decimals: 6,
                    name: "Kujira",
                    png:
                      "https://raw.githubusercontent.com/cosmos/chain-registry/master/kujira/images/kuji.png",
                    svg:
                      "https://raw.githubusercontent.com/cosmos/chain-registry/master/kujira/images/kuji.svg",
                    symbol: "KUJI"
                  },
                  trace: nil
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

  test "loads a market status", %{channel: channel} do
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

  test "loads a market health", %{channel: channel} do
    {:ok, market} =
      Ghost.get_market(
        channel,
        #  Mainnet KUJI-USK
        "kujira1aakur92cpmlygdcecruk5t8zjqtjnkf8fs8qlhhzuy5hkcrjddfs585grm"
      )

    {:ok, %Kujira.Orca.Market{} = market} = Ghost.load_orca_market(channel, market)
    [{%Decimal{}, val} | _] = Map.to_list(market.health)
    assert val > 0
  end

  test "fetches all markets", %{channel: channel} do
    {:ok, markets} = Ghost.list_markets(channel)
    [%Ghost.Market{} | _] = markets
    assert Enum.count(markets) > 10
  end

  test "loads a position", %{channel: channel} do
    {:ok, market} =
      Ghost.get_market(
        channel,
        "kujira1aakur92cpmlygdcecruk5t8zjqtjnkf8fs8qlhhzuy5hkcrjddfs585grm"
      )

    {:ok, position} =
      Ghost.load_position(channel, market, "kujira1gee7m7kygxuc4xk483ceuqcfczv48ygt27xgwk")

    assert %Position{
             collateral_amount: 10_000_000,
             debt_amount: _,
             debt_shares: 867_378,
             holder: "kujira1gee7m7kygxuc4xk483ceuqcfczv48ygt27xgwk",
             market:
               {Ghost.Market, "kujira1aakur92cpmlygdcecruk5t8zjqtjnkf8fs8qlhhzuy5hkcrjddfs585grm"}
           } = position
  end

  test "streams positions", %{channel: channel} do
    {:ok, market} =
      Ghost.get_market(
        channel,
        "kujira1aakur92cpmlygdcecruk5t8zjqtjnkf8fs8qlhhzuy5hkcrjddfs585grm"
      )

    {:ok, vault} = Kujira.Contract.get(channel, market.vault)
    {:ok, vault} = Ghost.load_vault(channel, vault)

    list =
      Ghost.stream_positions(channel, market, vault)
      |> Stream.take(202)
      |> Enum.to_list()

    # TODO: verify only 2 gRPC calls have been made to get this
    assert Enum.count(list) == 202

    assert Enum.all?(list, fn
             %Ghost.Position{} ->
               true

             _ ->
               false
           end)
  end

  test "extracts position change events from a transaction" do
    # Deposit + Borrow
    %{tx_response: response} =
      load_tx("F8BF63756503756325AFBB481D70DD0200FDD55F7603CDEB4C07FD9BE4F49219")

    changes = Ghost.Position.from_tx_response(response)

    assert changes ==
             [
               {{Ghost.Market,
                 "kujira1aakur92cpmlygdcecruk5t8zjqtjnkf8fs8qlhhzuy5hkcrjddfs585grm"},
                "kujira13tdp9dluewvh4hyq2r3ytmkxkfd9qcfu0xwaue", :borrow},
               {{Ghost.Market,
                 "kujira1aakur92cpmlygdcecruk5t8zjqtjnkf8fs8qlhhzuy5hkcrjddfs585grm"},
                "kujira13tdp9dluewvh4hyq2r3ytmkxkfd9qcfu0xwaue", :deposit}
             ]

    #  Repay +
    %{tx_response: response} =
      load_tx("7B73E4CEF376DB6D1E1D8E81B4656194722738044675898B02D130B1CFE61008")

    changes = Ghost.Position.from_tx_response(response)

    assert changes ==
             [
               {{Kujira.Ghost.Market,
                 "kujira1aakur92cpmlygdcecruk5t8zjqtjnkf8fs8qlhhzuy5hkcrjddfs585grm"},
                "kujira1xhnls8dtd88356g0lgg38kn6r2xgpr85ecwkgu", :withdraw},
               {{Kujira.Ghost.Market,
                 "kujira1aakur92cpmlygdcecruk5t8zjqtjnkf8fs8qlhhzuy5hkcrjddfs585grm"},
                "kujira1xhnls8dtd88356g0lgg38kn6r2xgpr85ecwkgu", :repay}
             ]
  end

  test "extracts vault status change events from a transaction" do
    # user withdraw
    %{tx_response: response} =
      load_tx("DA0185467777977D4E326F1EAC9AD03C46C93240C21013E4A91812BCD5BBE4D6")

    changes = Ghost.Vault.Status.from_tx_response(response)

    assert changes == [
             {{Ghost.Vault, "kujira1jelmu9tdmr6hqg0d6qw4g6c9mwrexrzuryh50fwcavcpthp5m0uq20853h"},
              :withdraw, 3_856_957_822}
           ]

    # user deposit
    %{tx_response: response} =
      load_tx("CEF02EC035FCC7A11F8F09A0584D1DE6BE49752276BE1FF4C8DF2167980FE6A7")

    changes = Ghost.Vault.Status.from_tx_response(response)

    assert changes == [
             {{Ghost.Vault, "kujira1jelmu9tdmr6hqg0d6qw4g6c9mwrexrzuryh50fwcavcpthp5m0uq20853h"},
              :deposit, 1_189_651_933}
           ]

    # market borrow
    %{tx_response: response} =
      load_tx("DB891408ED72A26F67C87FCFD98ED585ED28CF2A10098FB2FEE1FC3F3E70E761")

    changes = Ghost.Vault.Status.from_tx_response(response)

    assert changes == [
             {{Ghost.Vault, "kujira1jelmu9tdmr6hqg0d6qw4g6c9mwrexrzuryh50fwcavcpthp5m0uq20853h"},
              :borrow, 1_600_000_000}
           ]

    # market repay
    %{tx_response: response} =
      load_tx("7B73E4CEF376DB6D1E1D8E81B4656194722738044675898B02D130B1CFE61008")

    changes = Ghost.Vault.Status.from_tx_response(response)

    assert changes == [
             {{Ghost.Vault, "kujira1w4yaama77v53fp0f9343t9w2f932z526vj970n2jv5055a7gt92sxgwypf"},
              :repay, 575_854_079}
           ]
  end
end
