defmodule Rolodex.RouteTest do
  use ExUnit.Case

  alias Rolodex.Mocks.{
    TestController,
    UserResponse,
    PaginatedUsersResponse,
    ErrorResponse,
    UserRequestBody
  }

  alias Rolodex.{
    Config,
    Route,
    Utils
  }

  alias Rolodex.Router.RouteInfo

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

  describe "#new/2" do
    setup [:setup_config]

    test "It builds a new Rolodex.Route for the specified controller action", %{config: config} do
      result =
        setup_route_info(
          controller: TestController,
          action: :index,
          verb: :get,
          path: "/v2/test",
          pipe_through: []
        )
        |> Route.new(config)

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
      result =
        setup_route_info(
          controller: TestController,
          action: :index,
          verb: :get,
          path: "/v2/test",
          pipe_through: [:web]
        )
        |> Route.new(config)

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
        setup_route_info(
          controller: TestController,
          action: :multi,
          verb: :get,
          path: "/api/nested/:nested_id/multi",
          pipe_through: []
        )
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
               pipe_through: []
             }
    end

    test "It uses the Phoenix route verb to pull out docs for a multi-headed controller action",
         %{
           config: config
         } do
      result =
        setup_route_info(
          controller: TestController,
          action: :verb_multi,
          verb: :post,
          path: "/api/nested/:nested_id/multi",
          pipe_through: []
        )
        |> Route.new(config)

      assert result == %Route{
               auth: %{JWTAuth: []},
               desc: "It's an action used for the same path with multiple HTTP actions",
               path_params: %{
                 nested_id: %{type: :uuid, required: true}
               },
               responses: %{
                 200 => %{type: :ref, ref: UserResponse},
                 404 => %{type: :ref, ref: ErrorResponse}
               },
               path: "/api/nested/:nested_id/multi",
               verb: :post,
               pipe_through: []
             }
    end

    test "Controller action params will win if in conflict with pipeline params", %{
      config: config
    } do
      %Route{auth: auth, headers: headers} =
        setup_route_info(
          controller: TestController,
          action: :conflicted,
          verb: :get,
          path: "/v2/test",
          pipe_through: [:api]
        )
        |> Route.new(config)

      assert headers == %{"X-Request-Id" => %{type: :string, required: true}}
      assert auth == %{JWTAuth: [], SharedAuth: []}
    end

    test "It processes request body and responses with plain maps", %{config: config} do
      %Route{body: body, responses: responses} =
        setup_route_info(
          controller: TestController,
          action: :with_bare_maps,
          verb: :get,
          path: "/v2/test",
          pipe_through: []
        )
        |> Route.new(config)

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

    test "It serializes query and path param schema refs", %{config: config} do
      %Route{query_params: query, path_params: path} =
        setup_route_info(
          controller: TestController,
          action: :params_via_schema,
          verb: :get,
          path: "/v2/test",
          pipe_through: []
        )
        |> Route.new(config)

      assert query == %{
               account_id: %{type: :uuid},
               team_id: %{
                 type: :integer,
                 maximum: 10,
                 minimum: 0,
                 required: true,
                 default: 2
               },
               created_at: %{type: :datetime},
               id: %{type: :uuid, desc: "The comment id"},
               text: %{type: :string},
               mentions: %{type: :list, of: [%{type: :uuid}]}
             }

      assert path == %{
               account_id: %{type: :uuid},
               team_id: %{
                 type: :integer,
                 maximum: 10,
                 minimum: 0,
                 required: true,
                 default: 2
               },
               created_at: %{type: :datetime},
               id: %{type: :uuid, desc: "The comment id"},
               text: %{type: :string},
               mentions: %{type: :list, of: [%{type: :uuid}]}
             }
    end

    test "It handles an undocumented route" do
      result =
        setup_route_info(
          controller: TestController,
          action: :undocumented,
          verb: :post,
          path: "/v2/test",
          pipe_through: []
        )
        |> Route.new(Config.new(BasicConfig))

      assert result == %Route{
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
  end

  defp setup_config(_), do: [config: Config.new(FullConfig)]

  defp setup_route_info(%RouteInfo{controller: controller, action: action} = route_info) do
    with {:ok, desc, metadata} <- Utils.fetch_doc_annotation(controller, action) do
      %{route_info | desc: desc, metadata: metadata}
    end
  end

  defp setup_route_info(params), do: params |> RouteInfo.new() |> setup_route_info()
end
