defmodule Rolodex.RouteTest do
  use ExUnit.Case

  alias Rolodex.{Config, Route, PipeThroughMap}

  describe "#new/3" do
    test "It takes elixir documentation and returns a Rolodex struct" do
      doc =
        {{:function, :index, 2}, 8, ["index(conn, _)"], %{"en" => "It ensures the app is alive"},
         %{headers: %{}}}

      actual = Route.new(doc, Config.new())

      expected = %Route{
        description: "It ensures the app is alive"
      }

      assert actual == expected
    end

    test "The documentation attributes takes priority" do
      doc =
        {{:function, :index, 2}, 8, ["index(conn, _)"], %{"en" => "It ensures the app is alive"},
         %{headers: %{foo: :baz}}}

      actual = Route.new(doc, Config.new(), headers: %{foo: :bar})

      expected = %Route{
        description: "It ensures the app is alive",
        headers: %{foo: :baz}
      }

      assert actual == expected
    end

    test "The keys will merge if possible" do
      doc =
        {{:function, :index, 2}, 8, ["index(conn, _)"], %{"en" => "It ensures the app is alive"},
         %{headers: %{bar: :baz}}}

      actual = Route.new(doc, Config.new(), headers: %{foo: :bar})

      expected = %Route{
        description: "It ensures the app is alive",
        headers: %{foo: :bar, bar: :baz}
      }

      assert actual == expected
    end
  end

  describe "#pipe_through_mapping/2" do
    test "It grabs takes the pipe through and returns a map" do
      config =
        Config.new(
          pipe_through_mapping: %{
            api: %{headers: %{foo: :bar}}
          }
        )

      actual = Route.pipe_through_mapping(:api, config)
      expected = PipeThroughMap.new(%{headers: %{foo: :bar}})

      assert actual == expected
    end

    test "It works with multiple pipe throughs" do
      config =
        Config.new(
          pipe_through_mapping: %{
            api: %{headers: %{foo: :bar}},
            auth: %{headers: %{authorization: :bar}}
          }
        )

      actual = Route.pipe_through_mapping([:api, :auth], config)
      expected = PipeThroughMap.new(%{headers: %{foo: :bar, authorization: :bar}})

      assert actual == expected
    end

    test "It returns an empty map when given nil" do
      assert Route.pipe_through_mapping(nil, Config.new()) == PipeThroughMap.new()
    end
  end
end
