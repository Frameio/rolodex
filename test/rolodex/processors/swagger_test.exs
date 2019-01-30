defmodule Rolodex.Processors.SwaggerTest do
  use ExUnit.Case

  alias Rolodex.Route
  alias Rolodex.Processors.Swagger
  alias Rolodex.Mocks.{User, NotFound}

  describe "#process/3" do
    test "Processes config, routes, and schemas into a serialized JSON blob" do
      config = Rolodex.Config.new(description: "foo", title: "bar", version: "1")
      schemas = %{User => User.to_schema_map()}

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
                           200 => %{
                             content: %{
                               "application/json" => %{
                                 "$ref" => "#/components/schemas/User"
                               }
                             }
                           },
                           201 => :ok
                         }
                       }
                     }
                   }
                 ],
                 "components" => %{
                   "schemas" => %{
                     "User" => %{
                       type: :object,
                       properties: %{
                         id: %{type: :string, format: :uuid},
                         email: %{type: :string},
                         another_thing: %{type: :string},
                         comment: %{
                           "$ref" => "#/components/schemas/Comment"
                         },
                         comments: %{
                           type: :array,
                           items: %{
                             "$ref" => "#/components/schemas/Comment"
                           }
                         },
                         comments_of_many_types: %{
                           type: :array,
                           items: %{
                             oneOf: [
                               %{type: :string},
                               %{
                                 "$ref" => "#/components/schemas/Comment"
                               }
                             ]
                           }
                         }
                       }
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
        User => User.to_schema_map(),
        NotFound => NotFound.to_schema_map()
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
                       200 => %{
                         content: %{
                           "application/json" => %{
                             "$ref" => "#/components/schemas/User"
                           }
                         }
                       },
                       201 => :ok,
                       203 => "moved permanently",
                       123 => %{"hello" => "world"},
                       404 => %{
                         content: %{
                           "application/json" => %{
                             "$ref" => "#/components/schemas/NotFound"
                           }
                         }
                       }
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
        User => User.to_schema_map(),
        NotFound => NotFound.to_schema_map()
      }

      assert Swagger.process_schemas(schemas) == %{
               "User" => %{
                 type: :object,
                 properties: %{
                   id: %{type: :string, format: :uuid},
                   email: %{type: :string},
                   another_thing: %{type: :string},
                   comment: %{
                     "$ref" => "#/components/schemas/Comment"
                   },
                   comments: %{
                     type: :array,
                     items: %{
                       "$ref" => "#/components/schemas/Comment"
                     }
                   },
                   comments_of_many_types: %{
                     type: :array,
                     items: %{
                       oneOf: [
                         %{type: :string},
                         %{
                           "$ref" => "#/components/schemas/Comment"
                         }
                       ]
                     }
                   }
                 }
               },
               "NotFound" => %{
                 type: :object,
                 properties: %{
                   message: %{type: :string}
                 }
               }
             }
    end
  end
end
