defmodule SwagTest do
  use ExUnit.Case
  doctest Swag

  alias Swag.{Config, PipeThroughMap}

  defmodule User do
    def to_json_schema() do
      %{
        "description" => "User response test"
      }
    end
  end

  defmodule Comment do
    def to_json_schema() do
      %{
        "description" => "Comment response test"
      }
    end
  end

  defmodule NotFound do
    def to_json_schema() do
      %{
        "description" => "Not found response test"
      }
    end
  end

  describe "#generate_schema_refs/2" do
    def generate_helper(swags) do
      swags
      |> Flow.from_enumerable()
      |> Flow.reduce(fn -> %{} end, &Swag.generate_schema_refs/2)
      |> Map.new()
    end

    test "Generates multiple schemas from multiple response types" do
      swags = [
        %Swag{
          responses: %{
            200 => User,
            404 => NotFound
          }
        }
      ]

      assert(
        generate_helper(swags) == %{
          User => %{
            "description" => "User response test"
          },
          NotFound => %{
            "description" => "Not found response test"
          }
        }
      )
    end

    test "Does not duplicate schemas" do
      swags = [
        %Swag{
          responses: %{
            200 => User,
            404 => NotFound
          }
        },
        %Swag{
          responses: %{
            200 => Comment,
            404 => NotFound
          }
        }
      ]

      assert(
        generate_helper(swags) == %{
          User => %{
            "description" => "User response test"
          },
          Comment => %{
            "description" => "Comment response test"
          },
          NotFound => %{
            "description" => "Not found response test"
          }
        }
      )
    end

    test "Handles non-generated schemas" do
      swags = [
        %Swag{
          responses: %{
            200 => User,
            201 => :ok,
            203 => "moved permanently",
            123 => %{"hello" => "world"},
            404 => NotFound
          }
        }
      ]

      assert(
        generate_helper(swags) == %{
          User => %{
            "description" => "User response test"
          },
          NotFound => %{
            "description" => "Not found response test"
          }
        }
      )
    end
  end

  describe "#find_action/2" do
  end

  describe "#new/3" do
    test "It takes elixir documentation and returns a Swag struct" do
      doc =
        {{:function, :index, 2}, 8, ["index(conn, _)"], %{"en" => "It ensures the app is alive"},
         %{headers: %{}}}

      actual = Swag.new(doc, Config.new())

      expected = %Swag{
        description: "It ensures the app is alive"
      }

      assert actual == expected
    end

    test "The documentation attributes takes priority" do
      doc =
        {{:function, :index, 2}, 8, ["index(conn, _)"], %{"en" => "It ensures the app is alive"},
         %{headers: %{foo: :baz}}}

      actual = Swag.new(doc, Config.new(), headers: %{foo: :bar})

      expected = %Swag{
        description: "It ensures the app is alive",
        headers: %{foo: :baz}
      }

      assert actual == expected
    end

    test "The keys will merge if possible" do
      doc =
        {{:function, :index, 2}, 8, ["index(conn, _)"], %{"en" => "It ensures the app is alive"},
         %{headers: %{bar: :baz}}}

      actual = Swag.new(doc, Config.new(), headers: %{foo: :bar})

      expected = %Swag{
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

      actual = Swag.pipe_through_mapping(:api, config)
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

      actual = Swag.pipe_through_mapping([:api, :auth], config)
      expected = PipeThroughMap.new(%{headers: %{foo: :bar, authorization: :bar}})

      assert actual == expected
    end

    test "It returns an empty map when given nil" do
      assert Swag.pipe_through_mapping(nil, Config.new()) == PipeThroughMap.new()
    end
  end
end
