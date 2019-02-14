defmodule RolodexTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  doctest Rolodex

  alias Rolodex.{Config, Route}

  alias Rolodex.Mocks.{
    Comment,
    FirstNested,
    NestedDemo,
    NotFound,
    Parent,
    SecondNested,
    TestRouter,
    User
  }

  describe "#run/1" do
    test "Generates documentation and writes out to destination" do
      config = Config.new(router: TestRouter, writer: %{module: Rolodex.Writers.Mock})
      result = capture_io(fn -> Rolodex.run(config) end) |> Jason.decode!()

      assert result == %{
               "components" => %{
                 "schemas" => %{
                   "Comment" => %{
                     "properties" => %{
                       "id" => %{"format" => "uuid", "type" => "string"},
                       "text" => %{
                         "type" => "string"
                       }
                     },
                     "type" => "object"
                   },
                   "NotFound" => %{
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
                     "properties" => %{
                       "comment" => %{"$ref" => "#/components/schemas/Comment"},
                       "comments" => %{
                         "items" => %{"$ref" => "#/components/schemas/Comment"},
                         "type" => "array"
                       },
                       "comments_of_many_types" => %{
                         "items" => %{
                           "oneOf" => [
                             %{
                               "type" => "string"
                             },
                             %{"$ref" => "#/components/schemas/Comment"}
                           ]
                         },
                         "type" => "array"
                       },
                       "email" => %{
                         "type" => "string"
                       },
                       "id" => %{"format" => "uuid", "type" => "string"},
                       "multi" => %{
                         "oneOf" => [
                           %{
                             "type" => "string"
                           },
                           %{"$ref" => "#/components/schemas/NotFound"}
                         ]
                       },
                       "parent" => %{"$ref" => "#/components/schemas/Parent"}
                     },
                     "type" => "object"
                   }
                 }
               },
               "info" => %{"description" => nil, "title" => nil, "version" => nil},
               "openapi" => "3.0.0",
               "paths" => %{
                 "/api/demo" => %{
                   "get" => %{
                     "parameters" => [
                       %{
                         "description" => "",
                         "in" => "header",
                         "name" => "X-Request-Id",
                         "required" => true,
                         "schema" => %{"format" => "uuid", "type" => "string"}
                       },
                       %{
                         "description" => "",
                         "in" => "path",
                         "name" => "account_id",
                         "required" => false,
                         "schema" => %{"format" => "uuid", "type" => "string"}
                       },
                       %{
                         "description" => "",
                         "in" => "query",
                         "name" => "id",
                         "required" => false,
                         "schema" => %{
                           "default" => 2,
                           "maximum" => 10,
                           "minimum" => 0,
                           "type" => "string"
                         }
                       },
                       %{
                         "description" => "",
                         "in" => "query",
                         "name" => "update",
                         "required" => false,
                         "schema" => %{
                           "type" => "boolean"
                         }
                       }
                     ],
                     "requestBody" => %{
                       "content" => %{
                         "application/json" => %{
                           "schema" => %{
                             "properties" => %{
                               "id" => %{"format" => "uuid", "type" => "string"},
                               "name" => %{
                                 "type" => "string"
                               }
                             },
                             "type" => "object"
                           }
                         }
                       }
                     },
                     "responses" => %{
                       "200" => %{
                         "content" => %{
                           "application/json" => %{
                             "schema" => %{"$ref" => "#/components/schemas/User"}
                           }
                         }
                       },
                       "201" => %{
                         "content" => %{
                           "application/json" => %{
                             "schema" => %{
                               "type" => "array",
                               "items" => %{
                                 "$ref" => "#/components/schemas/User"
                               }
                             }
                           }
                         }
                       },
                       "404" => %{
                         "content" => %{
                           "application/json" => %{
                             "schema" => %{
                               "properties" => %{
                                 "message" => %{
                                   "type" => "string"
                                 },
                                 "status" => %{
                                   "type" => "integer"
                                 }
                               },
                               "type" => "object"
                             }
                           }
                         }
                       }
                     },
                     "summary" => "It's a test!"
                   }
                 },
                 "/api/demo/{id}" => %{
                   "post" => %{
                     "parameters" => [
                       %{
                         "description" => "",
                         "in" => "header",
                         "name" => "X-Request-Id",
                         "required" => false,
                         "schema" => %{
                           "type" => "string"
                         }
                       }
                     ],
                     "requestBody" => %{},
                     "responses" => %{},
                     "summary" => ""
                   }
                 }
               }
             }
    end
  end

  describe "#generate_routes/1" do
    test "Generates a list of %Route{} structs for the given router" do
      result =
        Config.new(router: TestRouter)
        |> Rolodex.generate_routes()

      assert result |> Enum.at(0) == %Route{
               body: %{
                 type: :object,
                 properties: %{
                   id: %{type: :uuid},
                   name: %{type: :string, desc: "The name"}
                 }
               },
               description: "It's a test!",
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
                 200 => %{type: :ref, ref: User},
                 201 => %{
                   type: :list,
                   of: [%{type: :ref, ref: User}]
                 },
                 404 => %{
                   type: :object,
                   properties: %{
                     status: %{type: :integer},
                     message: %{type: :string}
                   }
                 }
               },
               tags: ["foo", "bar"],
               verb: :get
             }

      assert result |> Enum.at(1) == %Route{
               description: "",
               headers: %{
                 "X-Request-Id" => %{type: :string}
               },
               path: "/api/demo/:id",
               verb: :post
             }
    end
  end

  describe "#generate_schemas/1" do
    test "Generates a map of unique schemas from route header, body, query, path, and responses" do
      routes = [
        %Route{
          headers: %{"X-Request-Id" => %{type: :uuid}},
          body: %{
            type: :object,
            properties: %{
              id: %{type: :uuid},
              nested: %{type: :ref, ref: User}
            }
          },
          query_params: %{id: %{type: :uuid}},
          path_params: %{nested: %{type: :ref, ref: NotFound}},
          responses: %{
            200 => %{type: :ref, ref: User}
          }
        },
        %Route{
          headers: %{comment: %{type: :ref, ref: Comment}},
          body: %{type: :ref, ref: Parent},
          query_params: %{nested: %{type: :ref, ref: NotFound}},
          path_params: %{id: %{type: :uuid}},
          responses: %{
            200 => %{type: :ref, ref: User}
          }
        }
      ]

      schemas = Rolodex.generate_schemas(routes)

      assert Map.keys(schemas) == [Comment, NotFound, Parent, User]
    end

    test "Ignores data that contains no Rolodex.Schema references" do
      routes = [
        %Route{
          headers: %{"X-Request-Id" => %{type: :uuid}},
          responses: %{
            200 => %{type: :ref, ref: User},
            201 => :ok,
            203 => "moved permanently",
            123 => %{"hello" => "world"},
            404 => %{type: :ref, ref: NestedDemo}
          }
        }
      ]

      schemas = Rolodex.generate_schemas(routes)

      assert Map.keys(schemas) == [
               Comment,
               FirstNested,
               NestedDemo,
               NotFound,
               Parent,
               SecondNested,
               User
             ]

      assert schemas == %{
               Comment => %{
                 type: :object,
                 desc: "A comment record",
                 properties: %{
                   id: %{
                     desc: "The comment id",
                     type: :uuid
                   },
                   text: %{
                     type: :string
                   }
                 }
               },
               FirstNested => %{
                 type: :object,
                 desc: nil,
                 properties: %{
                   nested: %{
                     type: :ref,
                     ref: SecondNested
                   }
                 }
               },
               NestedDemo => %{
                 type: :object,
                 desc: nil,
                 properties: %{
                   nested: %{
                     type: :ref,
                     ref: FirstNested
                   }
                 }
               },
               NotFound => %{
                 type: :object,
                 desc: "Not found response",
                 properties: %{
                   message: %{
                     type: :string
                   }
                 }
               },
               Parent => %{
                 type: :object,
                 desc: nil,
                 properties: %{
                   child: %{
                     type: :ref,
                     ref: User
                   }
                 }
               },
               SecondNested => %{
                 type: :object,
                 desc: nil,
                 properties: %{
                   id: %{
                     type: :uuid
                   }
                 }
               },
               User => %{
                 desc: "A user record",
                 properties: %{
                   comment: %{
                     type: :ref,
                     ref: Comment
                   },
                   comments: %{
                     of: [
                       %{
                         type: :ref,
                         ref: Comment
                       }
                     ],
                     type: :list
                   },
                   comments_of_many_types: %{
                     desc: "List of text or comment",
                     of: [
                       %{
                         type: :string
                       },
                       %{
                         type: :ref,
                         ref: Comment
                       }
                     ],
                     type: :list
                   },
                   email: %{
                     desc: "The email of the user",
                     type: :string
                   },
                   id: %{
                     desc: "The id of the user",
                     type: :uuid
                   },
                   multi: %{
                     of: [
                       %{
                         type: :string
                       },
                       %{
                         type: :ref,
                         ref: NotFound
                       }
                     ],
                     type: :one_of
                   },
                   parent: %{
                     type: :ref,
                     ref: Parent
                   }
                 },
                 type: :object
               }
             }
    end
  end
end
