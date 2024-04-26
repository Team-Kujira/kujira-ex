defmodule KujiraTokenTest do
  alias Kujira.Token
  use ExUnit.Case
  use Kujira.TestHelpers

  doctest Kujira.Token

  test "a native token correctly", %{channel: channel} do
    {:ok, token} = Token.from_denom(channel, "ukuji")
    assert token == %Token{denom: "ukuji", decimals: 6}
  end

  test "an ibc token correctly", %{channel: channel} do
    {:ok, token} =
      Token.from_denom(
        channel,
        "ibc/FE98AAD68F02F03565E9FA39A5E627946699B2B07115889ED812D8BA639576A9"
      )

    assert token == %Token{
             denom: "ibc/FE98AAD68F02F03565E9FA39A5E627946699B2B07115889ED812D8BA639576A9",
             decimals: 6,
             trace: %Token.Trace{
               base_denom: "uusdc",
               path: "transfer/channel-62"
             }
           }
  end
end
