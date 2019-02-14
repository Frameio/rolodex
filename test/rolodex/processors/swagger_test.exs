defmodule Rolodex.Processors.SwaggerTest do
  use ExUnit.Case

  alias Rolodex.{Route, Schema}
  alias Rolodex.Processors.Swagger
  alias Rolodex.Mocks.{User, NotFound}

  describe "#process/3" do
    test "Processes config, routes, and schemas into a serialized JSON blob" do
      config = Rolodex.Config.new(description: "foo", title: "bar", version: "1")
      schemas = %{User => Schema.to_map(User)}

      routes = [
        %Route{
          description: "It does a thing",
          path: "/foo",
          verb: :get,
          body: %{
            type: :object,
            properties: %{
              name: %{type: :string}
            }
          },
          responses: %{
            200 => %{type: :ref, ref: User},
            201 => :ok
          }
        }
      ]

      result = Swagger.process(config, routes, schemas) |> Jason.decode!()

      assert result == %{
               "openapi" => "3.0.0",
               "info" => %{
                 "title" => config.title,
                 "description" => config.description,
                 "version" => config.version
               },
               "paths" => %{
                 "/foo" => %{
                   "get" => %{
                     "summary" => "It does a thing",
                     "parameters" => [],
                     "requestBody" => %{
                       "content" => %{
                         "application/json" => %{
                           "schema" => %{
                             "type" => "object",
                             "properties" => %{
                               "name" => %{
                                 "type" => "string"
                               }
                             }
                           }
                         }
                       }
                     },
                     "responses" => %{
                       "200" => %{
                         "content" => %{
                           "application/json" => %{
                             "schema" => %{
                               "$ref" => "#/components/schemas/User"
                             }
                           }
                         }
                       },
                       "201" => %{
                         "description" => "OK"
                       }
                     }
                   }
                 }
               },
               "components" => %{
                 "schemas" => %{
                   "User" => %{
                     "type" => "object",
                     "properties" => %{
                       "id" => %{"type" => "string", "format" => "uuid"},
                       "email" => %{
                         "type" => "string"
                       },
                       "comment" => %{
                         "$ref" => "#/components/schemas/Comment"
                       },
                       "comments" => %{
                         "type" => "array",
                         "items" => %{
                           "$ref" => "#/components/schemas/Comment"
                         }
                       },
                       "comments_of_many_types" => %{
                         "type" => "array",
                         "items" => %{
                           "oneOf" => [
                             %{
                               "type" => "string"
                             },
                             %{
                               "$ref" => "#/components/schemas/Comment"
                             }
                           ]
                         }
                       },
                       "multi" => %{
                         "oneOf" => [
                           %{
                             "type" => "string"
                           },
                           %{"$ref" => "#/components/schemas/NotFound"}
                         ]
                       },
                       "parent" => %{
                         "$ref" => "#/components/schemas/Parent"
                       }
                     }
                   }
                 }
               }
             }
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

  describe "#process_routes/1" do
    test "It takes a list of routes and schemas and returns a formatted map" do
      routes = [
        %Route{
          description: "It does a thing",
          headers: %{
            "X-Request-Id" => %{type: :uuid, required: true}
          },
          body: %{
            type: :object,
            properties: %{
              name: %{type: :string}
            }
          },
          query_params: %{
            id: %{
              type: :integer,
              maximum: 10,
              minimum: 0,
              required: true,
              default: 2
            },
            update: %{type: :boolean}
          },
          path_params: %{
            account_id: %{type: :uuid}
          },
          responses: %{
            200 => %{type: :ref, ref: User},
            201 => :ok,
            404 => %{type: :ref, ref: NotFound}
          },
          path: "/foo",
          verb: :get
        }
      ]

      processed = Swagger.process_routes(routes)

      assert processed == %{
               "/foo" => %{
                 get: %{
                   summary: "It does a thing",
                   parameters: [
                     %{
                       in: :header,
                       name: "X-Request-Id",
                       description: "",
                       required: true,
                       schema: %{
                         type: :string,
                         format: :uuid
                       }
                     },
                     %{
                       in: :path,
                       name: :account_id,
                       description: "",
                       required: false,
                       schema: %{
                         type: :string,
                         format: :uuid
                       }
                     },
                     %{
                       in: :query,
                       name: :id,
                       description: "",
                       required: true,
                       schema: %{
                         type: :integer,
                         maximum: 10,
                         minimum: 0,
                         default: 2
                       }
                     },
                     %{
                       in: :query,
                       name: :update,
                       description: "",
                       required: false,
                       schema: %{
                         type: :boolean
                       }
                     }
                   ],
                   requestBody: %{
                     content: %{
                       "application/json" => %{
                         schema: %{
                           type: :object,
                           properties: %{
                             name: %{
                               type: :string
                             }
                           }
                         }
                       }
                     }
                   },
                   responses: %{
                     200 => %{
                       content: %{
                         "application/json" => %{
                           schema: %{
                             "$ref" => "#/components/schemas/User"
                           }
                         }
                       }
                     },
                     201 => %{description: "OK"},
                     404 => %{
                       content: %{
                         "application/json" => %{
                           schema: %{
                             "$ref" => "#/components/schemas/NotFound"
                           }
                         }
                       }
                     }
                   }
                 }
               }
             }
    end

    test "It collects routes by path" do
      routes = [
        %Route{
          path: "/foo",
          verb: :get,
          description: "GET /foo",
          responses: %{200 => %{type: :ref, ref: User}}
        },
        %Route{
          path: "/foo/:id",
          verb: :get,
          description: "GET /foo/{id}",
          responses: %{200 => %{type: :ref, ref: User}}
        },
        %Route{
          path: "/foo/:id",
          verb: :post,
          description: "POST /foo/{id}",
          responses: %{200 => %{type: :ref, ref: User}}
        }
      ]

      assert Swagger.process_routes(routes) == %{
               "/foo" => %{
                 get: %{
                   summary: "GET /foo",
                   requestBody: %{},
                   parameters: [],
                   responses: %{
                     200 => %{
                       content: %{
                         "application/json" => %{
                           schema: %{
                             "$ref" => "#/components/schemas/User"
                           }
                         }
                       }
                     }
                   }
                 }
               },
               "/foo/{id}" => %{
                 get: %{
                   summary: "GET /foo/{id}",
                   requestBody: %{},
                   parameters: [],
                   responses: %{
                     200 => %{
                       content: %{
                         "application/json" => %{
                           schema: %{
                             "$ref" => "#/components/schemas/User"
                           }
                         }
                       }
                     }
                   }
                 },
                 post: %{
                   summary: "POST /foo/{id}",
                   requestBody: %{},
                   parameters: [],
                   responses: %{
                     200 => %{
                       content: %{
                         "application/json" => %{
                           schema: %{
                             "$ref" => "#/components/schemas/User"
                           }
                         }
                       }
                     }
                   }
                 }
               }
             }
    end
  end

  describe "#process_schemas/1" do
    test "It processes the schemas" do
      schemas = %{
        User => Schema.to_map(User),
        NotFound => Schema.to_map(NotFound)
      }

      assert Swagger.process_schemas(schemas) == %{
               "User" => %{
                 type: :object,
                 properties: %{
                   id: %{type: :string, format: :uuid},
                   email: %{
                     type: :string
                   },
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
                         %{
                           type: :string
                         },
                         %{
                           "$ref" => "#/components/schemas/Comment"
                         }
                       ]
                     }
                   },
                   multi: %{
                     oneOf: [
                       %{
                         type: :string
                       },
                       %{"$ref" => "#/components/schemas/NotFound"}
                     ]
                   },
                   parent: %{
                     "$ref" => "#/components/schemas/Parent"
                   }
                 }
               },
               "NotFound" => %{
                 type: :object,
                 properties: %{
                   message: %{
                     type: :string
                   }
                 }
               }
             }
    end
  end
end
