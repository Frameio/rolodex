defmodule Swag.Processors.SwaggerTest do
  use ExUnit.Case

  alias Swag.Processors.Swagger

  defmodule User do
    def __object__(:name), do: "User"
    def __object__(:type), do: :schema
  end

  defmodule NotFound do
    def __object__(:name), do: "NotFound"
    def __object__(:type), do: :schema
  end

  describe "#process/3" do
    test "It takes a swag struct and converts it into a swagger formatted json fragment" do
      schemas = %{
        User => %{
          "description" => "User response test"
        },
        NotFound => %{
          "description" => "Not found response test"
        }
      }

      swag = %Swag{
        description: "It does a thing",
        responses: %{
          200 => User,
          201 => :ok,
          203 => "moved permanently",
          123 => %{"hello" => "world"},
          404 => NotFound
        },
        path: "/foo",
        verb: :get
      }

      actual = Swagger.process(swag, schemas, %{})

      expected =
        Jason.encode!(%{
          "/foo" => %{
            "get" => %{
              "description" => "It does a thing",
              "responses" => %{
                200 => "#/components/schemas/User",
                201 => :ok,
                203 => "moved permanently",
                123 => %{"hello" => "world"},
                404 => "#/components/schemas/NotFound"
              }
            }
          }
        })

      assert actual == expected
    end
  end

  describe "#init/1" do
    test "It returns a json fragment of things that should be written once and sets the open api version" do
      config = Swag.Config.new(description: "foo", title: "bar", version: "1")

      assert Swagger.init(config) == """
             {\"info\":{
               \"description\":\"foo\",
               \"title\":\"bar\",
               \"version\":\"1\"},
             \"openapi\":\"3.0.0\",
             \"paths\":[
             """
    end
  end

  describe "#finalize/1" do
    test "It closes the json fragment" do
      assert Swagger.finalize(:any) == """
             ]}
             """
    end
  end
end
