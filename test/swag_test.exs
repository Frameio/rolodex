defmodule SwagTest do
  use ExUnit.Case
  doctest Swag

  test "greets the world" do
    assert Swag.hello() == :world
  end
end
