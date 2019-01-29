defmodule RolodexTest do
  use ExUnit.Case
  doctest Rolodex

  alias Rolodex.Route
  alias Rolodex.Mocks.{User, NotFound}

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
        Rolodex.generate_schemas(routes) == %{
          User => %{
            "description" => "A user record",
            "properties" => %{
              "another_thing" => %{"type" => "string"},
              "email" => %{"type" => "string"},
              "id" => %{"format" => "uuid", "type" => "string"}
            },
            "type" => "object"
          },
          NotFound => %{
            "description" => "Not found response",
            "properties" => %{
              "message" => %{"type" => "string"}
            },
            "type" => "object"
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
            404 => NotFound
          }
        }
      ]

      assert(
        Rolodex.generate_schemas(routes) == %{
          User => %{
            "description" => "A user record",
            "properties" => %{
              "another_thing" => %{"type" => "string"},
              "email" => %{"type" => "string"},
              "id" => %{"format" => "uuid", "type" => "string"}
            },
            "type" => "object"
          },
          NotFound => %{
            "description" => "Not found response",
            "properties" => %{
              "message" => %{"type" => "string"}
            },
            "type" => "object"
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
        Rolodex.generate_schemas(routes) == %{
          User => %{
            "description" => "A user record",
            "properties" => %{
              "another_thing" => %{"type" => "string"},
              "email" => %{"type" => "string"},
              "id" => %{"format" => "uuid", "type" => "string"}
            },
            "type" => "object"
          },
          NotFound => %{
            "description" => "Not found response",
            "properties" => %{
              "message" => %{"type" => "string"}
            },
            "type" => "object"
          }
        }
      )
    end
  end

  describe "#write/2" do
    # TODO
  end
end
