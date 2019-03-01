defmodule Rolodex.Processors.SwaggerTest do
  use ExUnit.Case

  alias Rolodex.{Config, Response, Route, Schema}
  alias Rolodex.Processors.Swagger
  alias Rolodex.Mocks.{ErrorResponse, User, UserResponse}

  describe "#process/3" do
    test "Processes config, routes, and schemas into a serialized JSON blob" do
      config =
        Config.new(
          description: "foo",
          title: "bar",
          version: "1",
          server_urls: ["https://api.example.com"]
        )

      refs = %{
        responses: %{
          UserResponse => Response.to_map(UserResponse)
        },
        schemas: %{
          User => Schema.to_map(User)
        }
      }

      routes = [
        %Route{
          desc: "It does a thing",
          path: "/foo",
          verb: :get,
          body: %{
            type: :object,
            properties: %{
              name: %{type: :string}
            }
          },
          responses: %{
            200 => %{type: :ref, ref: UserResponse}
          }
        }
      ]

      result = Swagger.process(config, routes, refs) |> Jason.decode!()

      assert result == %{
               "openapi" => "3.0.0",
               "info" => %{
                 "title" => config.title,
                 "description" => config.description,
                 "version" => config.version
               },
               "servers" => [%{"url" => "https://api.example.com"}],
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
                         "$ref" => "#/components/responses/UserResponse"
                       }
                     }
                   }
                 }
               },
               "components" => %{
                 "responses" => %{
                   "UserResponse" => %{
                     "content" => %{
                       "application/json" => %{
                         "examples" => %{"response" => %{"id" => "1"}},
                         "schema" => %{
                           "$ref" => "#/components/schemas/User"
                         }
                       }
                     },
                     "description" => "A single user entity response"
                   }
                 },
                 "schemas" => %{
                   "User" => %{
                     "type" => "object",
                     "description" => "A user record",
                     "required" => ["id", "email"],
                     "properties" => %{
                       "id" => %{
                         "type" => "string",
                         "format" => "uuid",
                         "description" => "The id of the user"
                       },
                       "email" => %{
                         "type" => "string",
                         "description" => "The email of the user"
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
                         "description" => "List of text or comment",
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
      config =
        Config.new(
          description: "foo",
          title: "bar",
          version: "1",
          server_urls: ["https://api.example.com"]
        )

      headers = Swagger.process_headers(config)

      assert headers == %{
               openapi: "3.0.0",
               servers: [%{url: "https://api.example.com"}],
               info: %{
                 title: config.title,
                 description: config.description,
                 version: config.version
               }
             }
    end
  end

  describe "#process_routes/1" do
    test "It takes a list of routes and refs and returns a formatted map" do
      routes = [
        %Route{
          desc: "It does a thing",
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
            account_id: %{type: :uuid, desc: "The account id"}
          },
          responses: %{
            200 => %{type: :ref, ref: UserResponse},
            201 => :ok,
            404 => %{type: :ref, ref: ErrorResponse}
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
                       required: true,
                       schema: %{
                         type: :string,
                         format: :uuid
                       }
                     },
                     %{
                       in: :path,
                       name: :account_id,
                       schema: %{
                         type: :string,
                         format: :uuid,
                         description: "The account id"
                       }
                     },
                     %{
                       in: :query,
                       name: :id,
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
                       "$ref" => "#/components/responses/UserResponse"
                     },
                     201 => %{description: "OK"},
                     404 => %{
                       "$ref" => "#/components/responses/ErrorResponse"
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
          desc: "GET /foo",
          responses: %{200 => %{type: :ref, ref: UserResponse}}
        },
        %Route{
          path: "/foo/:id",
          verb: :get,
          desc: "GET /foo/{id}",
          responses: %{200 => %{type: :ref, ref: UserResponse}}
        },
        %Route{
          path: "/foo/:id",
          verb: :post,
          desc: "POST /foo/{id}",
          responses: %{200 => %{type: :ref, ref: UserResponse}}
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
                       "$ref" => "#/components/responses/UserResponse"
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
                       "$ref" => "#/components/responses/UserResponse"
                     }
                   }
                 },
                 post: %{
                   summary: "POST /foo/{id}",
                   requestBody: %{},
                   parameters: [],
                   responses: %{
                     200 => %{
                       "$ref" => "#/components/responses/UserResponse"
                     }
                   }
                 }
               }
             }
    end
  end

  describe "#process_refs/1" do
    test "It processes the response and schema refs" do
      refs = %{
        responses: %{
          UserResponse => Response.to_map(UserResponse)
        },
        schemas: %{
          User => Schema.to_map(User)
        }
      }

      assert Swagger.process_refs(refs) == %{
               responses: %{
                 "UserResponse" => %{
                   content: %{
                     "application/json" => %{
                       examples: %{response: %{id: "1"}},
                       schema: %{
                         "$ref" => "#/components/schemas/User"
                       }
                     }
                   },
                   description: "A single user entity response"
                 }
               },
               schemas: %{
                 "User" => %{
                   type: :object,
                   description: "A user record",
                   required: [:id, :email],
                   properties: %{
                     id: %{
                       type: :string,
                       format: :uuid,
                       description: "The id of the user"
                     },
                     email: %{
                       type: :string,
                       description: "The email of the user"
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
                       description: "List of text or comment",
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
                 }
               }
             }
    end
  end
end
