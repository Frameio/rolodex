defmodule RolodexTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias Rolodex.{Config, Route}

  alias Rolodex.Mocks.{
    Comment,
    FirstNested,
    NestedDemo,
    NotFound,
    Parent,
    SecondNested,
    TestRouter,
    User,
    UserResponse,
    PaginatedUsersResponse,
    ErrorResponse,
    UserRequestBody
  }

  defmodule ConfigNoFilters do
    use Rolodex.Config
    def spec(), do: [router: TestRouter]
  end

  defmodule ConfigWithFilters do
    use Rolodex.Config

    def spec() do
      [
        router: TestRouter,
        filters: [%{path: "/api/demo/:id", verb: :delete}],
        writer: Rolodex.Writers.Mock,
        server_urls: ["https://api.example.com"]
      ]
    end

    def auth_spec() do
      [
        JWTAuth: [
          type: "http",
          scheme: "bearer"
        ],
        TokenAuth: [type: "oauth2"],
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

  describe "#run/1" do
    test "Generates documentation and writes out to destination" do
      result =
        capture_io(fn ->
          ConfigWithFilters
          |> Config.new()
          |> Rolodex.run()
        end)
        |> Jason.decode!()

      assert result == %{
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
                   "ErrorResponse" => %{
                     "content" => %{
                       "application/json" => %{
                         "examples" => %{},
                         "schema" => %{
                           "properties" => %{
                             "message" => %{"type" => "string"},
                             "status" => %{"type" => "integer"}
                           },
                           "type" => "object"
                         }
                       }
                     },
                     "description" => "An error response"
                   },
                   "PaginatedUsersResponse" => %{
                     "content" => %{
                       "application/json" => %{
                         "examples" => %{
                           "response" => %{"value" => [%{"id" => "1"}]}
                         },
                         "schema" => %{
                           "properties" => %{
                             "page" => %{"type" => "integer"},
                             "total" => %{"type" => "integer"},
                             "users" => %{
                               "items" => %{
                                 "$ref" => "#/components/schemas/User"
                               },
                               "type" => "array"
                             }
                           },
                           "type" => "object"
                         }
                       }
                     },
                     "description" => "A paginated list of user entities"
                   },
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
                     "description" => "A single user entity response"
                   }
                 },
                 "schemas" => %{
                   "Comment" => %{
                     "description" => "A comment record",
                     "properties" => %{
                       "id" => %{
                         "format" => "uuid",
                         "type" => "string",
                         "description" => "The comment id"
                       },
                       "text" => %{
                         "type" => "string"
                       }
                     },
                     "type" => "object"
                   },
                   "NotFound" => %{
                     "description" => "Not found response",
                     "properties" => %{
                       "message" => %{
                         "type" => "string"
                       }
                     },
                     "type" => "object"
                   },
                   "Parent" => %{
                     "properties" => %{"child" => %{"$ref" => "#/components/schemas/User"}},
                     "type" => "object"
                   },
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
                   "TokenAuth" => %{"type" => "oauth2"},
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
               },
               "info" => %{"description" => nil, "title" => nil, "version" => nil},
               "openapi" => "3.0.0",
               "servers" => [%{"url" => "https://api.example.com"}],
               "paths" => %{
                 "/api/demo" => %{
                   "get" => %{
                     "security" => [
                       %{"JWTAuth" => []},
                       %{"OAuth" => ["user.read"]},
                       %{"TokenAuth" => ["user.read"]}
                     ],
                     "parameters" => [
                       %{
                         "in" => "header",
                         "name" => "X-Request-Id",
                         "required" => true,
                         "schema" => %{"format" => "uuid", "type" => "string"}
                       },
                       %{
                         "in" => "path",
                         "name" => "account_id",
                         "schema" => %{"format" => "uuid", "type" => "string"}
                       },
                       %{
                         "in" => "query",
                         "name" => "id",
                         "schema" => %{
                           "default" => 2,
                           "maximum" => 10,
                           "minimum" => 0,
                           "type" => "string"
                         }
                       },
                       %{
                         "in" => "query",
                         "name" => "update",
                         "schema" => %{
                           "type" => "boolean"
                         }
                       }
                     ],
                     "requestBody" => %{
                       "$ref" => "#/components/requestBodies/UserRequestBody"
                     },
                     "responses" => %{
                       "200" => %{
                         "$ref" => "#/components/responses/UserResponse"
                       },
                       "201" => %{
                         "$ref" => "#/components/responses/PaginatedUsersResponse"
                       },
                       "404" => %{
                         "$ref" => "#/components/responses/ErrorResponse"
                       }
                     },
                     "summary" => "It's a test!"
                   }
                 },
                 "/api/demo/{id}" => %{
                   "post" => %{
                     "security" => [%{"JWTAuth" => []}],
                     "parameters" => [
                       %{
                         "in" => "header",
                         "name" => "X-Request-Id",
                         "schema" => %{
                           "type" => "string"
                         }
                       }
                     ],
                     "responses" => %{},
                     "summary" => ""
                   },
                   "put" => %{
                     "security" => [],
                     "parameters" => [],
                     "requestBody" => %{
                       "content" => %{
                         "application/json" => %{
                           "schema" => %{
                             "type" => "object",
                             "properties" => %{
                               "id" => %{
                                 "type" => "string",
                                 "format" => "uuid"
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
                               "type" => "object",
                               "properties" => %{
                                 "id" => %{
                                   "type" => "string",
                                   "format" => "uuid"
                                 }
                               }
                             }
                           }
                         }
                       }
                     },
                     "summary" => ""
                   }
                 },
                 "/api/multi" => %{
                   "get" => %{
                     "parameters" => [],
                     "responses" => %{
                       "200" => %{"$ref" => "#/components/responses/UserResponse"},
                       "404" => %{"$ref" => "#/components/responses/ErrorResponse"}
                     },
                     "security" => [%{"JWTAuth" => []}],
                     "summary" => "It's an action used for multiple routes"
                   }
                 },
                 "/api/nested/{nested_id}/multi" => %{
                   "get" => %{
                     "parameters" => [
                       %{
                         "in" => "path",
                         "name" => "nested_id",
                         "required" => true,
                         "schema" => %{"format" => "uuid", "type" => "string"}
                       }
                     ],
                     "responses" => %{
                       "200" => %{"$ref" => "#/components/responses/UserResponse"},
                       "404" => %{"$ref" => "#/components/responses/ErrorResponse"}
                     },
                     "security" => [%{"JWTAuth" => []}],
                     "summary" => "It's an action used for multiple routes"
                   }
                 }
               }
             }
    end
  end

  describe "#generate_routes/1" do
    test "Generates a list of %Route{} structs for the given router" do
      result =
        ConfigNoFilters
        |> Config.new()
        |> Rolodex.generate_routes()

      assert result |> Enum.at(0) == %Route{
               auth: %{
                 JWTAuth: [],
                 TokenAuth: ["user.read"],
                 OAuth: ["user.read"]
               },
               body: %{type: :ref, ref: UserRequestBody},
               desc: "It's a test!",
               headers: %{
                 "X-Request-Id" => %{type: :uuid, required: true}
               },
               metadata: %{public: true},
               path: "/api/demo",
               path_params: %{
                 account_id: %{type: :uuid}
               },
               query_params: %{
                 id: %{
                   type: :string,
                   maximum: 10,
                   minimum: 0,
                   required: false,
                   default: 2
                 },
                 update: %{type: :boolean}
               },
               responses: %{
                 200 => %{type: :ref, ref: UserResponse},
                 201 => %{type: :ref, ref: PaginatedUsersResponse},
                 404 => %{type: :ref, ref: ErrorResponse}
               },
               tags: ["foo", "bar"],
               verb: :get
             }

      assert result |> Enum.at(1) == %Route{
               desc: "",
               auth: %{JWTAuth: []},
               headers: %{
                 "X-Request-Id" => %{type: :string}
               },
               path: "/api/demo/:id",
               verb: :post
             }
    end

    test "It filters out routes that match the config" do
      num_routes =
        ConfigWithFilters
        |> Config.new()
        |> Rolodex.generate_routes()
        |> length()

      assert num_routes == 5
    end
  end

  describe "#generate_refs/1" do
    test "Generates a map of unique schemas from route header, body, query, path, and responses" do
      routes = [
        %Route{
          headers: %{"X-Request-Id" => %{type: :uuid}},
          body: %{type: :ref, ref: UserRequestBody},
          query_params: %{id: %{type: :uuid}},
          path_params: %{nested: %{type: :ref, ref: NotFound}},
          responses: %{
            200 => %{type: :ref, ref: UserResponse}
          }
        },
        %Route{
          headers: %{comment: %{type: :ref, ref: Comment}},
          body: %{type: :ref, ref: Parent},
          query_params: %{nested: %{type: :ref, ref: NotFound}},
          path_params: %{id: %{type: :uuid}},
          responses: %{
            200 => %{type: :ref, ref: UserResponse}
          }
        }
      ]

      %{responses: responses, request_bodies: request_bodies, schemas: schemas} =
        Rolodex.generate_refs(routes)

      assert Map.keys(responses) == [UserResponse]
      assert Map.keys(request_bodies) == [UserRequestBody]
      assert Map.keys(schemas) == [Comment, NotFound, Parent, User]
    end

    test "Ignores data that contains no Rolodex.Schema references" do
      routes = [
        %Route{
          headers: %{"X-Request-Id" => %{type: :uuid}},
          responses: %{
            200 => %{type: :ref, ref: UserResponse},
            201 => :ok,
            203 => "moved permanently",
            123 => %{"hello" => "world"},
            404 => %{type: :ref, ref: NestedDemo}
          }
        }
      ]

      %{responses: responses, request_bodies: request_bodies, schemas: schemas} =
        Rolodex.generate_refs(routes)

      assert Map.keys(request_bodies) == []
      assert Map.keys(responses) == [UserResponse]

      assert Map.keys(schemas) == [
               Comment,
               FirstNested,
               NestedDemo,
               NotFound,
               Parent,
               SecondNested,
               User
             ]
    end
  end
end
