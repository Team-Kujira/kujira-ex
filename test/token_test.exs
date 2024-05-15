defmodule KujiraTokenTest do
  alias Kujira.Token
  use ExUnit.Case
  use Kujira.TestHelpers

  doctest Kujira.Token

  test "a native token correctly", %{channel: channel} do
    {:ok, token} = Token.from_denom(channel, "ukuji")
    assert %Token{denom: "ukuji"} = token
  end

  test "an ibc token correctly", %{channel: channel} do
    {:ok, token} =
      Token.from_denom(
        channel,
        "ibc/FE98AAD68F02F03565E9FA39A5E627946699B2B07115889ED812D8BA639576A9"
      )

    %Token{
      denom: "ibc/FE98AAD68F02F03565E9FA39A5E627946699B2B07115889ED812D8BA639576A9",
      trace: %Token.Trace{
        base_denom: "uusdc",
        path: "transfer/channel-62"
      }
    } = token
  end

  test "fetches local chain-registry metadata correctly", %{channel: channel} do
    {:ok, token} = Token.from_denom(channel, "ukuji")

    assert token == %Token{
             denom: "ukuji",
             meta: %Kujira.Token.Meta{
               coingecko_id: "kujira",
               name: "Kujira",
               decimals: 6,
               png:
                 "https://raw.githubusercontent.com/cosmos/chain-registry/master/kujira/images/kuji.png",
               svg:
                 "https://raw.githubusercontent.com/cosmos/chain-registry/master/kujira/images/kuji.svg",
               symbol: "KUJI"
             },
             trace: nil
           }
  end

  test "fetches ibc chain-registry metadata correctly", %{channel: channel} do
    {:ok, token} =
      Token.from_denom(
        channel,
        "ibc/FE98AAD68F02F03565E9FA39A5E627946699B2B07115889ED812D8BA639576A9"
      )

    assert token == %Token{
             denom: "ibc/FE98AAD68F02F03565E9FA39A5E627946699B2B07115889ED812D8BA639576A9",
             trace: %Token.Trace{
               base_denom: "uusdc",
               path: "transfer/channel-62"
             },
             meta: %Token.Meta{
               name: "USDC",
               symbol: "USDC",
               decimals: 6,
               coingecko_id: "usd-coin",
               png:
                 "https://raw.githubusercontent.com/cosmos/chain-registry/master/noble/images/USDCoin.png",
               svg:
                 "https://raw.githubusercontent.com/cosmos/chain-registry/master/noble/images/USDCoin.svg"
             }
           }
  end

  test "an unknown IBC token", %{channel: channel} do
    assert Token.from_denom(
             channel,
             "ibc/FE98AAD68F02F03565E9FA39A5E627946699B2B07115889ED812D8BA639576A8"
           ) ==
             {:error,
              %GRPC.RPCError{
                message:
                  "FE98AAD68F02F03565E9FA39A5E627946699B2B07115889ED812D8BA639576A8: denomination trace not found",
                status: 5
              }}
  end
end
