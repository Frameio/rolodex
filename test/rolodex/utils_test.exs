defmodule Rolodex.UtilsTest do
  use ExUnit.Case

  alias Rolodex.Utils

  describe "#indifferent_find/2" do
    test "It will lookup indifferently" do
      data = %{} |> Map.put(:foo, :bar) |> Map.put("bar", :baz)

      assert Utils.indifferent_find(data, :foo) == :bar
      assert Utils.indifferent_find(data, "foo") == :bar
      assert Utils.indifferent_find(data, :bar) == :baz
      assert Utils.indifferent_find(data, "bar") == :baz
    end
  end
end
