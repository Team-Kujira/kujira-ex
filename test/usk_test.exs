defmodule KujiraUskTest do
  alias Kujira.Usk.Position
  alias Kujira.Usk
  use ExUnit.Case
  use Kujira.TestHelpers

  doctest Kujira.Usk
  doctest Kujira.Usk.Position

  #  Mainnet ATOM
  @market "kujira1ecgazyd0waaj3g7l9cmy5gulhxkps2gmxu9ghducvuypjq68mq2smfdslf"
  #  Mainnet ATOM
  @margin "kujira1m0z0kk0qqug74n9u9ul23e28x5fszr628h20xwt6jywjpp64xn4qkxmjq3"

  test "queries a market", %{channel: channel} do
    assert Usk.get_market(
             channel,
             #  Mainnet ATOM
             @market
           ) ==
             {:ok,
              %Kujira.Usk.Market{
                address: "kujira1ecgazyd0waaj3g7l9cmy5gulhxkps2gmxu9ghducvuypjq68mq2smfdslf",
                collateral_oracle_denom: "ATOM",
                collateral_token: %Kujira.Token{
                  denom: "ibc/27394FB092D2ECCD56123C74F36E4C1F926001CEADA9CA97EA622B25F41E5EB2",
                  meta: %Kujira.Token.Meta{
                    coingecko_id: "cosmos",
                    decimals: 6,
                    name: "Cosmos Hub Atom",
                    png:
                      "https://raw.githubusercontent.com/cosmos/chain-registry/master/cosmoshub/images/atom.png",
                    svg:
                      "https://raw.githubusercontent.com/cosmos/chain-registry/master/cosmoshub/images/atom.svg",
                    symbol: "ATOM"
                  },
                  trace: %Kujira.Token.Trace{base_denom: "uatom", path: "transfer/channel-0"}
                },
                full_liquidation_threshold: 1_000_000_000,
                interest_rate: Decimal.new("0.01"),
                liquidation_ratio: Decimal.new("0.1"),
                max_debt: 1_000_000_000_000,
                max_ltv: Decimal.new("0.6"),
                mint_fee: Decimal.new("0.001"),
                orca_queue:
                  {Kujira.Orca.Queue,
                   "kujira1q8y46xg993cqg3xjycyw2334tepey7dmnh5jk2psutrz3fc69teskctgfc"},
                owner: "kujira10d07y265gmmuvt4z0w9aw880jnsr700jt23ame",
                stable_token: %Kujira.Token{
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
                stable_token_admin:
                  "kujira1qk00h5atutpsv900x202pxx42npjr9thg58dnqpa72f2p7m2luase444a7",
                status: :not_loaded
              }}
  end

  test "loads a market status", %{channel: channel} do
    {:ok, market} =
      Usk.get_market(
        channel,
        @market
      )

    {:ok, market} = Usk.load_market(channel, market)

    assert %Kujira.Usk.Market{
             status: %Usk.Market.Status{}
           } = market

    assert market.status.minted > 0
  end

  test "loads a market health", %{channel: channel} do
    {:ok, market} =
      Usk.get_market(
        channel,
        @market
      )

    {:ok, %Kujira.Orca.Market{} = market} = Usk.load_orca_market(channel, market)
    [{%Decimal{}, val} | _] = Map.to_list(market.health)
    assert val > 0
  end

  test "loads a margin health", %{channel: channel} do
    {:ok, %{market: market}} =
      Usk.get_margin(
        channel,
        @margin
      )

    {:ok, %Kujira.Orca.Market{} = market} = Usk.load_orca_market(channel, market)
    [{%Decimal{}, _} | _] = Map.to_list(market.health)
  end

  test "fetches all markets", %{channel: channel} do
    {:ok, markets} = Usk.list_markets(channel)
    [%Usk.Market{} | _] = markets
    assert Enum.count(markets) > 10
  end

  test "loads a position", %{channel: channel} do
    {:ok, market} =
      Usk.get_market(
        channel,
        "kujira1247c0yvkxf3sf4zzu88sye5aqpqckjsmllk78uk3a89ezermldcs6ldxx2"
      )

    {:ok, position} =
      Usk.load_position(
        channel,
        market,
        "kujira1gee7m7kygxuc4xk483ceuqcfczv48ygt27xgwk"
      )

    assert %Position{
             collateral_amount: 1_000_000,
             debt_amount: _,
             holder: "kujira1gee7m7kygxuc4xk483ceuqcfczv48ygt27xgwk",
             interest_amount: _,
             market:
               {Kujira.Usk.Market,
                "kujira1247c0yvkxf3sf4zzu88sye5aqpqckjsmllk78uk3a89ezermldcs6ldxx2"},
             mint_amount: 44149
           } = position
  end

  test "streams positions", %{channel: channel} do
    {:ok, market} =
      Usk.get_market(
        channel,
        @market
      )

    list =
      Usk.stream_positions(channel, market)
      |> Stream.take(202)
      |> Enum.to_list()

    # TODO: verify only 2 gRPC calls have been made to get this
    assert Enum.count(list) == 202

    assert Enum.all?(list, fn
             %Usk.Position{} ->
               true

             _ ->
               false
           end)
  end

  test "extracts position change events from a transaction" do
    # Deposit + Borrow
    %{tx_response: response} =
      load_tx("E0DBF1C7818127C11A62042E3D6EF8EA46A57ECA672FAFC23561DD9A93B5B814")

    changes = Usk.Position.from_tx_response(response)

    assert changes ==
             [
               {{Usk.Market, @market}, "kujira1uyphdztvh3r4jv23utrht7qtgf0ref34fdyyhq", :mint},
               {{Usk.Market, @market}, "kujira1uyphdztvh3r4jv23utrht7qtgf0ref34fdyyhq", :deposit}
             ]

    #  Repay +
    %{tx_response: response} =
      load_tx("22DA1A8C3F4DB10A2744C8E92D2018C4B5AB7FB940FE25A97B1C2D274C0181E5")

    changes = Usk.Position.from_tx_response(response)

    assert changes ==
             [
               {{Kujira.Usk.Market, @market}, "kujira19rnt6nmlzn6awdnq07hksygltt0kzvkaxu8njp",
                :withdraw},
               {{Kujira.Usk.Market, @market}, "kujira19rnt6nmlzn6awdnq07hksygltt0kzvkaxu8njp",
                :burn}
             ]
  end
end
