defmodule Rolodex.Processors.SwaggerTest do
  use ExUnit.Case

  alias Rolodex.Route
  alias Rolodex.Processors.Swagger

  defmodule User do
    def __object__(:name), do: "User"
    def __object__(:type), do: :schema
  end

  defmodule NotFound do
    def __object__(:name), do: "NotFound"
    def __object__(:type), do: :schema
  end

  describe "#process/3" do
    test "Processes config, routes, and schemas into a serialized JSON blob" do
      config = Rolodex.Config.new(description: "foo", title: "bar", version: "1")

      schemas = %{
        User => %{
          "description" => "User response test"
        }
      }

      routes = [
        %Route{
          description: "It does a thing",
          path: "/foo",
          verb: :get,
          responses: %{
            200 => User,
            201 => :ok
          }
        }
      ]

      assert Swagger.process(config, routes, schemas) ==
               Jason.encode!(%{
                 "openapi" => "3.0.0",
                 "info" => %{
                   "title" => config.title,
                   "description" => config.description,
                   "version" => config.version
                 },
                 "paths" => [
                   %{
                     "/foo" => %{
                       "get" => %{
                         "description" => "It does a thing",
                         "responses" => %{
                           200 => "#/components/schemas/User",
                           201 => :ok
                         }
                       }
                     }
                   }
                 ],
                 "components" => %{
                   "schemas" => %{
                     "User" => %{
                       "description" => "User response test"
                     }
                   }
                 }
               })
    end
  end

  describe "#process_headers/1" do
    test "It returns a map of top-level metadata" do
      config = Rolodex.Config.new(description: "foo", title: "bar", version: "1")
      headers = Swagger.process_headers(config)

      assert headers == %{
               "openapi" => "3.0.0",
               "info" => %{
                 "title" => config.title,
                 "description" => config.description,
                 "version" => config.version
               }
             }
    end
  end

  describe "#process_routes/2" do
    test "It takes a list of swag routes and schemas and returns a formatted map" do
      schemas = %{
        User => %{
          "description" => "User response test"
        },
        NotFound => %{
          "description" => "Not found response test"
        }
      }

      routes = [
        %Route{
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
      ]

      processed = Swagger.process_routes(routes, schemas)

      assert processed == [
               %{
                 "/foo" => %{
                   get: %{
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
               }
             ]
    end
  end

  describe "#process_schemas/1" do
    test "It processes the schemas" do
      schemas = %{
        User => %{
          "description" => "User response test"
        },
        NotFound => %{
          "description" => "Not found response test"
        }
      }

      assert Swagger.process_schemas(schemas) == %{
               "User" => %{
                 "description" => "User response test"
               },
               "NotFound" => %{
                 "description" => "Not found response test"
               }
             }
    end
  end
end
