defmodule Rolodex.Processors.OpenAPITest do
  use ExUnit.Case

  alias Rolodex.{
    Config,
    Response,
    Route,
    RequestBody,
    Schema,
    Headers
  }

  alias Rolodex.Processors.OpenAPI

  alias Rolodex.Mocks.{
    ErrorResponse,
    User,
    UserRequestBody,
    UserResponse,
    RateLimitHeaders
  }

  defmodule(BasicConfig, do: use(Rolodex.Config))

  defmodule FullConfig do
    use Rolodex.Config

    def spec() do
      [
        description: "foo",
        title: "bar",
        version: "1",
        server_urls: ["https://api.example.com"]
      ]
    end

    def auth_spec() do
      [
        JWTAuth: [
          type: "http",
          scheme: "bearer"
        ],
        OAuth: [
          type: "oauth2",
          flows: [
            authorization_code: [
              authorization_url: "https://applications.frame.io/oauth2/authorize",
              token_url: "https://applications.frame.io/oauth2/token",
              scopes: [
                "user.read",
                "account.read",
                "account.write"
              ]
            ]
          ]
        ]
      ]
    end
  end

  describe "#process/3" do
    test "Processes config, routes, and schemas into a serialized JSON blob" do
      config = Config.new(FullConfig)

      refs = %{
        request_bodies: %{
          UserRequestBody => RequestBody.to_map(UserRequestBody)
        },
        responses: %{
          UserResponse => Response.to_map(UserResponse)
        },
        schemas: %{
          User => Schema.to_map(User)
        },
        headers: %{
          RateLimitHeaders => Headers.to_map(RateLimitHeaders)
        }
      }

      routes = [
        %Route{
          id: "foo",
          auth: %{
            JWTAuth: [],
            OAuth: ["user.read"]
          },
          desc: "It does a thing",
          path: "/foo",
          verb: :get,
          body: %{type: :ref, ref: UserRequestBody},
          responses: %{
            200 => %{type: :ref, ref: UserResponse}
          }
        }
      ]

      result = OpenAPI.process(config, routes, refs) |> Jason.decode!()

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
                     "operationId" => "foo",
                     "summary" => "It does a thing",
                     "tags" => [],
                     "security" => [
                       %{"JWTAuth" => []},
                       %{"OAuth" => ["user.read"]}
                     ],
                     "parameters" => [],
                     "requestBody" => %{
                       "$ref" => "#/components/requestBodies/UserRequestBody"
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
                 "requestBodies" => %{
                   "UserRequestBody" => %{
                     "content" => %{
                       "application/json" => %{
                         "examples" => %{
                           "request" => %{"value" => %{"id" => "1"}}
                         },
                         "schema" => %{
                           "$ref" => "#/components/schemas/User"
                         }
                       }
                     },
                     "description" => "A single user entity request body"
                   }
                 },
                 "responses" => %{
                   "UserResponse" => %{
                     "content" => %{
                       "application/json" => %{
                         "examples" => %{
                           "response" => %{"value" => %{"id" => "1"}}
                         },
                         "schema" => %{
                           "$ref" => "#/components/schemas/User"
                         }
                       }
                     },
                     "headers" => %{
                       "limited" => %{
                         "description" => "Have you been rate limited",
                         "schema" => %{"type" => "boolean"}
                       }
                     },
                     "description" => "A single user entity response"
                   }
                 },
                 "schemas" => %{
                   "User" => %{
                     "type" => "object",
                     "description" => "A user record",
                     "required" => ["parent", "id", "email"],
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
                       "short_comments" => %{
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
                       },
                       "private" => %{
                         "type" => "boolean"
                       },
                       "archived" => %{
                         "type" => "boolean"
                       },
                       "active" => %{
                         "type" => "boolean"
                       }
                     }
                   }
                 },
                 "securitySchemes" => %{
                   "JWTAuth" => %{
                     "type" => "http",
                     "scheme" => "bearer"
                   },
                   "OAuth" => %{
                     "type" => "oauth2",
                     "flows" => %{
                       "authorizationCode" => %{
                         "authorizationUrl" => "https://applications.frame.io/oauth2/authorize",
                         "tokenUrl" => "https://applications.frame.io/oauth2/token",
                         "scopes" => [
                           "user.read",
                           "account.read",
                           "account.write"
                         ]
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
      config = Config.new(FullConfig)

      headers = OpenAPI.process_headers(config)

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
          id: "foo",
          desc: "It does a thing",
          auth: %{JWTAuth: []},
          headers: %{
            "X-Request-Id" => %{type: :uuid, required: true}
          },
          body: %{type: :ref, ref: UserRequestBody},
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

      processed = OpenAPI.process_routes(routes, Config.new(BasicConfig))

      assert processed == %{
               "/foo" => %{
                 get: %{
                   operationId: "foo",
                   summary: "It does a thing",
                   tags: [],
                   security: [%{JWTAuth: []}],
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
                       description: "The account id",
                       schema: %{
                         type: :string,
                         format: :uuid
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
                     "$ref" => "#/components/requestBodies/UserRequestBody"
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
          id: "foo",
          path: "/foo",
          verb: :get,
          desc: "GET /foo",
          responses: %{200 => %{type: :ref, ref: UserResponse}}
        },
        %Route{
          id: "foobar",
          path: "/foo/:id",
          verb: :get,
          desc: "GET /foo/{id}",
          responses: %{200 => %{type: :ref, ref: UserResponse}}
        },
        %Route{
          id: "foobuzz",
          path: "/foo/:id",
          verb: :post,
          desc: "POST /foo/{id}",
          responses: %{200 => %{type: :ref, ref: UserResponse}}
        }
      ]

      assert OpenAPI.process_routes(routes, Config.new(BasicConfig)) == %{
               "/foo" => %{
                 get: %{
                   operationId: "foo",
                   summary: "GET /foo",
                   security: [],
                   parameters: [],
                   tags: [],
                   responses: %{
                     200 => %{
                       "$ref" => "#/components/responses/UserResponse"
                     }
                   }
                 }
               },
               "/foo/{id}" => %{
                 get: %{
                   operationId: "foobar",
                   summary: "GET /foo/{id}",
                   security: [],
                   parameters: [],
                   tags: [],
                   responses: %{
                     200 => %{
                       "$ref" => "#/components/responses/UserResponse"
                     }
                   }
                 },
                 post: %{
                   operationId: "foobuzz",
                   summary: "POST /foo/{id}",
                   security: [],
                   parameters: [],
                   tags: [],
                   responses: %{
                     200 => %{
                       "$ref" => "#/components/responses/UserResponse"
                     }
                   }
                 }
               }
             }
    end

    test "It processes fields that should become formatted strings" do
      routes = [
        %Route{
          id: "foo",
          path: "/foo",
          verb: :get,
          desc: "GET /foo",
          query_params: %{
            id: %{type: :uuid},
            email: %{type: :email},
            url: %{type: :uri},
            date: %{type: :date},
            date_and_time: %{type: :datetime},
            other_date_and_time: %{type: :"date-time"},
            pass: %{type: :password},
            chunk: %{type: :byte},
            chunks: %{type: :binary}
          },
          responses: %{200 => %{type: :ref, ref: UserResponse}}
        }
      ]

      assert OpenAPI.process_routes(routes, Config.new(BasicConfig)) == %{
               "/foo" => %{
                 get: %{
                   operationId: "foo",
                   summary: "GET /foo",
                   security: [],
                   tags: [],
                   parameters: [
                     %{
                       in: :query,
                       name: :chunk,
                       schema: %{
                         type: :string,
                         format: :byte
                       }
                     },
                     %{
                       in: :query,
                       name: :chunks,
                       schema: %{
                         type: :string,
                         format: :binary
                       }
                     },
                     %{
                       in: :query,
                       name: :date,
                       schema: %{
                         type: :string,
                         format: :date
                       }
                     },
                     %{
                       in: :query,
                       name: :date_and_time,
                       schema: %{
                         type: :string,
                         format: :"date-time"
                       }
                     },
                     %{
                       in: :query,
                       name: :email,
                       schema: %{
                         type: :string,
                         format: :email
                       }
                     },
                     %{
                       in: :query,
                       name: :id,
                       schema: %{
                         type: :string,
                         format: :uuid
                       }
                     },
                     %{
                       in: :query,
                       name: :other_date_and_time,
                       schema: %{
                         type: :string,
                         format: :"date-time"
                       }
                     },
                     %{
                       in: :query,
                       name: :pass,
                       schema: %{
                         type: :string,
                         format: :password
                       }
                     },
                     %{
                       in: :query,
                       name: :url,
                       schema: %{
                         type: :string,
                         format: :uri
                       }
                     }
                   ],
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
        request_bodies: %{
          UserRequestBody => RequestBody.to_map(UserRequestBody)
        },
        responses: %{
          UserResponse => Response.to_map(UserResponse)
        },
        schemas: %{
          User => Schema.to_map(User)
        },
        headers: %{
          RateLimitHeaders => Headers.to_map(RateLimitHeaders)
        }
      }

      assert OpenAPI.process_refs(refs, Config.new(FullConfig)) == %{
               requestBodies: %{
                 "UserRequestBody" => %{
                   content: %{
                     "application/json" => %{
                       examples: %{request: %{value: %{id: "1"}}},
                       schema: %{
                         "$ref" => "#/components/schemas/User"
                       }
                     }
                   },
                   description: "A single user entity request body"
                 }
               },
               responses: %{
                 "UserResponse" => %{
                   content: %{
                     "application/json" => %{
                       examples: %{response: %{value: %{id: "1"}}},
                       schema: %{
                         "$ref" => "#/components/schemas/User"
                       }
                     }
                   },
                   headers: %{
                     "limited" => %{
                       description: "Have you been rate limited",
                       schema: %{type: :boolean}
                     }
                   },
                   description: "A single user entity response"
                 }
               },
               schemas: %{
                 "User" => %{
                   type: :object,
                   description: "A user record",
                   required: [:parent, :id, :email],
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
                     short_comments: %{
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
                     },
                     private: %{type: :boolean},
                     archived: %{type: :boolean},
                     active: %{type: :boolean}
                   }
                 }
               },
               securitySchemes: %{
                 "JWTAuth" => %{
                   "type" => "http",
                   "scheme" => "bearer"
                 },
                 "OAuth" => %{
                   "type" => "oauth2",
                   "flows" => %{
                     "authorizationCode" => %{
                       "authorizationUrl" => "https://applications.frame.io/oauth2/authorize",
                       "tokenUrl" => "https://applications.frame.io/oauth2/token",
                       "scopes" => [
                         "user.read",
                         "account.read",
                         "account.write"
                       ]
                     }
                   }
                 }
               }
             }
    end
  end
end
