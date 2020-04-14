defmodule RolodexTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  defmodule BadConfig do
    use Rolodex.Config

    def spec() do
      [server_urls: ["https://api.example.com"]]
    end

    def render_groups_spec() do
      [[router: Rolodex.Mocks.TestRouter, writer_opts: []]]
    end
  end

  defmodule TestConfig do
    use Rolodex.Config

    def spec() do
      [server_urls: ["https://api.example.com"]]
    end

    def render_groups_spec() do
      [
        [router: Rolodex.Mocks.TestRouter, writer: Rolodex.Writers.Mock],
        [
          router: Rolodex.Mocks.MiniTestRouter,
          writer: Rolodex.Writers.Mock
        ]
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

  defp get_result(renders, idx) do
    renders
    |> Enum.at(idx)
    |> elem(1)
    |> Jason.decode!()
  end

  describe "#run/1" do
    test "Returns an error when config is malformed" do
      capture_io(fn ->
        renders =
          BadConfig
          |> Rolodex.Config.new()
          |> Rolodex.run()

        assert renders |> Enum.at(0) == {:error, {:error, :file_name_missing}}
      end)
    end

    test "Generates documentation and writes out to destination for multiple render groups" do
      capture_io(fn ->
        renders =
          TestConfig
          |> Rolodex.Config.new()
          |> Rolodex.run()

        assert length(renders) == 2

        assert get_result(renders, 0) == %{
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
                     "MultiResponse" => %{
                       "description" => nil,
                       "headers" => %{
                         "total" => %{
                           "description" => "Total entries to be retrieved",
                           "schema" => %{"type" => "integer"}
                         },
                         "per-page" => %{
                           "description" => "Total entries per page of results",
                           "schema" => %{"type" => "integer"}
                         },
                         "limited" => %{
                           "description" => "Have you been rate limited",
                           "schema" => %{"type" => "boolean"}
                         }
                       },
                       "content" => %{
                         "application/json" => %{
                           "schema" => %{
                             "$ref" => "#/components/schemas/User"
                           }
                         },
                         "application/lolsob" => %{
                           "schema" => %{
                             "type" => "array",
                             "items" => %{
                               "$ref" => "#/components/schemas/Comment"
                             }
                           }
                         }
                       }
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
                       "headers" => %{
                         "total" => %{
                           "description" => "Total entries to be retrieved",
                           "schema" => %{"type" => "integer"}
                         },
                         "per-page" => %{
                           "description" => "Total entries per page of results",
                           "schema" => %{"type" => "integer"}
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
                       "operationId" => "",
                       "security" => [
                         %{"JWTAuth" => []},
                         %{"OAuth" => ["user.read"]},
                         %{"TokenAuth" => ["user.read"]}
                       ],
                       "parameters" => [
                         %{
                           "in" => "header",
                           "name" => "per-page",
                           "required" => true,
                           "description" => "Total entries per page of results",
                           "schema" => %{"type" => "integer"}
                         },
                         %{
                           "in" => "header",
                           "name" => "total",
                           "description" => "Total entries to be retrieved",
                           "schema" => %{"type" => "integer"}
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
                       "summary" => "It's a test!",
                       "tags" => ["foo", "bar"]
                     }
                   },
                   "/api/demo/{id}" => %{
                     "delete" => %{
                       "operationId" => "",
                       "parameters" => [],
                       "responses" => %{},
                       "security" => [],
                       "summary" => "",
                       "tags" => []
                     },
                     "post" => %{
                       "operationId" => "",
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
                       "summary" => "",
                       "tags" => []
                     },
                     "put" => %{
                       "operationId" => "",
                       "security" => [],
                       "parameters" => [
                         %{
                           "in" => "header",
                           "name" => "X-Request-Id",
                           "required" => true,
                           "schema" => %{"format" => "uuid", "type" => "string"}
                         }
                       ],
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
                       "summary" => "",
                       "tags" => []
                     }
                   },
                   "/api/multi" => %{
                     "get" => %{
                       "operationId" => "",
                       "parameters" => [],
                       "responses" => %{
                         "200" => %{"$ref" => "#/components/responses/UserResponse"},
                         "201" => %{"$ref" => "#/components/responses/MultiResponse"},
                         "404" => %{"$ref" => "#/components/responses/ErrorResponse"}
                       },
                       "security" => [%{"JWTAuth" => []}],
                       "summary" => "It's an action used for multiple routes",
                       "tags" => []
                     }
                   },
                   "/api/nested/{nested_id}/multi" => %{
                     "get" => %{
                       "operationId" => "",
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
                       "summary" => "It's an action used for multiple routes",
                       "tags" => []
                     }
                   },
                   "/api/partials" => %{
                     "get" => %{
                       "parameters" => [
                         %{
                           "in" => "path",
                           "name" => "account_id",
                           "schema" => %{
                             "type" => "string",
                             "format" => "uuid"
                           }
                         },
                         %{
                           "in" => "path",
                           "name" => "created_at",
                           "schema" => %{
                             "type" => "string",
                             "format" => "date-time"
                           }
                         },
                         %{
                           "in" => "path",
                           "name" => "id",
                           "description" => "The comment id",
                           "schema" => %{
                             "type" => "string",
                             "format" => "uuid"
                           }
                         },
                         %{
                           "in" => "path",
                           "name" => "mentions",
                           "schema" => %{
                             "type" => "array",
                             "items" => %{
                               "type" => "string",
                               "format" => "uuid"
                             }
                           }
                         },
                         %{
                           "in" => "path",
                           "name" => "team_id",
                           "required" => true,
                           "schema" => %{
                             "type" => "integer",
                             "maximum" => 10,
                             "minimum" => 0,
                             "default" => 2
                           }
                         },
                         %{
                           "in" => "path",
                           "name" => "text",
                           "schema" => %{
                             "type" => "string"
                           }
                         },
                         %{
                           "in" => "query",
                           "name" => "account_id",
                           "schema" => %{
                             "type" => "string",
                             "format" => "uuid"
                           }
                         },
                         %{
                           "in" => "query",
                           "name" => "created_at",
                           "schema" => %{
                             "type" => "string",
                             "format" => "date-time"
                           }
                         },
                         %{
                           "in" => "query",
                           "name" => "id",
                           "description" => "The comment id",
                           "schema" => %{
                             "type" => "string",
                             "format" => "uuid"
                           }
                         },
                         %{
                           "in" => "query",
                           "name" => "mentions",
                           "schema" => %{
                             "type" => "array",
                             "items" => %{
                               "type" => "string",
                               "format" => "uuid"
                             }
                           }
                         },
                         %{
                           "in" => "query",
                           "name" => "team_id",
                           "required" => true,
                           "schema" => %{
                             "type" => "integer",
                             "maximum" => 10,
                             "minimum" => 0,
                             "default" => 2
                           }
                         },
                         %{
                           "in" => "query",
                           "name" => "text",
                           "schema" => %{
                             "type" => "string"
                           }
                         }
                       ],
                       "responses" => %{
                         "200" => %{"$ref" => "#/components/responses/UserResponse"}
                       },
                       "operationId" => "",
                       "security" => [],
                       "summary" => "",
                       "tags" => []
                     }
                   }
                 }
               }

        assert get_result(renders, 1) == %{
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
                       "headers" => %{
                         "total" => %{
                           "description" => "Total entries to be retrieved",
                           "schema" => %{"type" => "integer"}
                         },
                         "per-page" => %{
                           "description" => "Total entries per page of results",
                           "schema" => %{"type" => "integer"}
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
                       "operationId" => "",
                       "security" => [
                         %{"JWTAuth" => []},
                         %{"OAuth" => ["user.read"]},
                         %{"TokenAuth" => ["user.read"]}
                       ],
                       "parameters" => [
                         %{
                           "in" => "header",
                           "name" => "per-page",
                           "required" => true,
                           "description" => "Total entries per page of results",
                           "schema" => %{"type" => "integer"}
                         },
                         %{
                           "in" => "header",
                           "name" => "total",
                           "description" => "Total entries to be retrieved",
                           "schema" => %{"type" => "integer"}
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
                       "summary" => "It's a test!",
                       "tags" => ["foo", "bar"]
                     }
                   }
                 }
               }
      end)
    end
  end
end
