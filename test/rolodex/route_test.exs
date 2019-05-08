defmodule Rolodex.RouteTest do
  use ExUnit.Case

  alias Phoenix.Router

  alias Rolodex.Mocks.{
    TestController,
    TestRouter,
    UserResponse,
    PaginatedUsersResponse,
    ErrorResponse,
    UserRequestBody
  }

  alias Rolodex.{Config, Route}

  defmodule(BasicConfig, do: use(Rolodex.Config))

  defmodule FullConfig do
    use Rolodex.Config

    def pipelines_spec() do
      %{
        api: %{
          auth: :SharedAuth,
          headers: %{"X-Request-Id" => %{type: :uuid, required: true}},
          query_params: %{foo: :string}
        },
        web: %{
          headers: %{"X-Request-Id" => %{type: :uuid, required: true}},
          query_params: %{foo: :string, bar: :boolean}
        },
        socket: %{
          headers: %{bar: :baz}
        }
      }
    end
  end

  describe "#matches_filter?/2" do
    setup [:setup_config]

    test "Always returns false when no filters provided", %{config: config} do
      routes =
        TestRouter.__routes__()
        |> Enum.map(&Route.new(&1, config))

      assert routes |> Enum.at(0) |> Route.matches_filter?(config) == false
      assert routes |> Enum.at(1) |> Route.matches_filter?(config) == false
    end

    test "Returns true when for a route that matches a filter map", %{config: config} do
      config = %Config{config | filters: [%{path: "/api/demo", verb: :get}]}

      routes =
        TestRouter.__routes__()
        |> Enum.map(&Route.new(&1, config))

      assert routes |> Enum.at(0) |> Route.matches_filter?(config) == true
      assert routes |> Enum.at(1) |> Route.matches_filter?(config) == false
    end

    test "Returns true for a route that matches a filter function", %{config: config} do
      config = %Config{
        config
        | filters: [
            fn
              %Route{path: "/api/demo/:id", verb: :post} ->
                true

              _ ->
                false
            end
          ]
      }

      routes =
        TestRouter.__routes__()
        |> Enum.map(&Route.new(&1, config))

      assert routes |> Enum.at(0) |> Route.matches_filter?(config) == false
      assert routes |> Enum.at(1) |> Route.matches_filter?(config) == true
    end
  end

  describe "#new/2" do
    setup [:setup_config]

    test "It builds a new Rolodex.Route for the specified controller action", %{config: config} do
      phoenix_route = %Router.Route{
        plug: TestController,
        opts: :index,
        path: "/v2/test",
        pipe_through: [],
        verb: :get
      }

      result = Route.new(phoenix_route, config)

      assert result == %Route{
               auth: %{
                 JWTAuth: [],
                 TokenAuth: ["user.read"],
                 OAuth: ["user.read"]
               },
               desc: "It's a test!",
               headers: %{
                 "total" => %{type: :integer, desc: "Total entries to be retrieved"},
                 "per-page" => %{
                   type: :integer,
                   required: true,
                   desc: "Total entries per page of results"
                 }
               },
               body: %{type: :ref, ref: UserRequestBody},
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
               path_params: %{
                 account_id: %{type: :uuid}
               },
               responses: %{
                 200 => %{type: :ref, ref: UserResponse},
                 201 => %{type: :ref, ref: PaginatedUsersResponse},
                 404 => %{type: :ref, ref: ErrorResponse}
               },
               metadata: %{public: true},
               tags: ["foo", "bar"],
               path: "/v2/test",
               pipe_through: [],
               verb: :get
             }
    end

    test "It merges controller action params into pipeline params", %{config: config} do
      phoenix_route = %Router.Route{
        plug: TestController,
        opts: :index,
        path: "/v2/test",
        pipe_through: [:web],
        verb: :get
      }

      result = Route.new(phoenix_route, config)

      assert result == %Route{
               auth: %{
                 JWTAuth: [],
                 TokenAuth: ["user.read"],
                 OAuth: ["user.read"]
               },
               desc: "It's a test!",
               headers: %{
                 "X-Request-Id" => %{type: :uuid, required: true},
                 "total" => %{type: :integer, desc: "Total entries to be retrieved"},
                 "per-page" => %{
                   type: :integer,
                   required: true,
                   desc: "Total entries per page of results"
                 }
               },
               body: %{type: :ref, ref: UserRequestBody},
               query_params: %{
                 id: %{
                   type: :string,
                   maximum: 10,
                   minimum: 0,
                   required: false,
                   default: 2
                 },
                 update: %{type: :boolean},
                 foo: %{type: :string},
                 bar: %{type: :boolean}
               },
               path_params: %{
                 account_id: %{type: :uuid}
               },
               responses: %{
                 200 => %{type: :ref, ref: UserResponse},
                 201 => %{type: :ref, ref: PaginatedUsersResponse},
                 404 => %{type: :ref, ref: ErrorResponse}
               },
               metadata: %{public: true},
               tags: ["foo", "bar"],
               path: "/v2/test",
               pipe_through: [:web],
               verb: :get
             }
    end

    test "It uses the Phoenix route path to pull out docs for a multi-headed controller action",
         %{
           config: config
         } do
      result =
        %Router.Route{
          plug: TestController,
          opts: :multi,
          path: "/api/nested/:nested_id/multi",
          verb: :get
        }
        |> Route.new(config)

      assert result == %Route{
               auth: %{JWTAuth: []},
               desc: "It's an action used for multiple routes",
               path_params: %{
                 nested_id: %{type: :uuid, required: true}
               },
               responses: %{
                 200 => %{type: :ref, ref: UserResponse},
                 404 => %{type: :ref, ref: ErrorResponse}
               },
               path: "/api/nested/:nested_id/multi",
               verb: :get,
               pipe_through: nil
             }
    end

    test "It returns nil if no path matches the Phoenix route path for a multi-headed controller action",
         %{
           config: config
         } do
      result =
        %Router.Route{
          plug: TestController,
          opts: :multi,
          path: "/multi/:nested_id/multi/non-existent",
          verb: :get
        }
        |> Route.new(config)

      assert result == nil
    end

    test "Controller action params will win if in conflict with pipeline params", %{
      config: config
    } do
      phoenix_route = %Router.Route{
        plug: TestController,
        opts: :conflicted,
        path: "/v2/test",
        pipe_through: [:api],
        verb: :get
      }

      %Route{auth: auth, headers: headers} = Route.new(phoenix_route, config)
      assert headers == %{"X-Request-Id" => %{type: :string, required: true}}
      assert auth == %{JWTAuth: [], SharedAuth: []}
    end

    test "It processes request body and responses with plain maps", %{config: config} do
      phoenix_route = %Router.Route{
        plug: TestController,
        opts: :with_bare_maps,
        path: "/v2/test",
        pipe_through: [],
        verb: :get
      }

      %Route{body: body, responses: responses} = Route.new(phoenix_route, config)

      assert body == %{
               type: :object,
               properties: %{id: %{type: :uuid}}
             }

      assert responses == %{
               200 => %{
                 type: :object,
                 properties: %{id: %{type: :uuid}}
               }
             }
    end

    test "It handles an undocumented route" do
      phoenix_route = %Router.Route{
        plug: TestController,
        opts: :undocumented,
        path: "/v2/test",
        pipe_through: [],
        verb: :post
      }

      assert Route.new(phoenix_route, Config.new(BasicConfig)) == %Route{
               desc: "",
               headers: %{},
               body: %{},
               query_params: %{},
               responses: %{},
               metadata: %{},
               tags: [],
               path: "/v2/test",
               pipe_through: [],
               verb: :post
             }
    end

    test "It handles a missing controller action" do
      phoenix_route = %Router.Route{
        plug: TestController,
        opts: :does_not_exist,
        path: "/v2/test",
        pipe_through: [],
        verb: :post
      }

      assert Route.new(phoenix_route, Config.new(BasicConfig)) == nil
    end
  end

  defp setup_config(_), do: [config: Config.new(FullConfig)]
end
