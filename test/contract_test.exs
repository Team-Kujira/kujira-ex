defmodule KujiraContractTest do
  alias Kujira.Contract
  use ExUnit.Case
  use Kujira.TestHelpers

  test "invaliates code_id on instantiate", %{channel: channel} do
    {:ok, block} = load_block(18_628_721)
  end
end
