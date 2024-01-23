defmodule KujiraTest do
  use ExUnit.Case
  doctest Kujira

  test "greets the world" do
    assert Kujira.hello() == :world
  end
end
