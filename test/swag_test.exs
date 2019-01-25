defmodule SwagTest do
  use ExUnit.Case
  doctest Swag

  alias Swag.Route

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

  describe "#generate_documentation/1" do
    # TODO
  end

  describe "#generate_routes/1" do
    # TODO
  end

  describe "#generate_schemas/1" do
    test "Generates multiple schemas from multiple response types" do
      routes = [
        %Route{
          responses: %{
            200 => User,
            404 => NotFound
          }
        }
      ]

      assert(
        Swag.generate_schemas(routes) == %{
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
      routes = [
        %Route{
          responses: %{
            200 => User,
            404 => NotFound
          }
        },
        %Route{
          responses: %{
            200 => Comment,
            404 => NotFound
          }
        }
      ]

      assert(
        Swag.generate_schemas(routes) == %{
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
      routes = [
        %Route{
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
        Swag.generate_schemas(routes) == %{
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

  describe "#write/2" do
    # TODO
  end
end
