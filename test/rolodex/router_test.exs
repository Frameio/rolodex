defmodule Rolodex.RouterTest do
  use ExUnit.Case

  alias Rolodex.{Config, Route, Router}

  alias Rolodex.Mocks.{
    TestPhoenixRouter,
    TestRouter,
    UserRequestBody,
    UserResponse,
    PaginatedUsersResponse,
    ErrorResponse,
    MultiResponse
  }

  defmodule(BasicConfig, do: use(Config))

  describe "macros" do
    test "It sets the expected private functions on the router module" do
      assert TestRouter.__router__(:phoenix_router) == TestPhoenixRouter

      assert TestRouter.__router__(:routes) == [
               put: "/api/demo/missing/:id",
               get: "/api/partials",
               get: "/api/nested/:nested_id/multi",
               get: "/api/multi",
               delete: "/api/demo/:id",
               put: "/api/demo/:id",
               post: "/api/demo/:id",
               get: "/api/demo"
             ]
    end
  end

  describe "#build_routes/2" do
    test "It builds %Rolodex.Route{} structs from the router data" do
      result = Router.build_routes(TestRouter, Config.new(BasicConfig))

      assert result == [
               %Route{
                 auth: %{JWTAuth: [], OAuth: ["user.read"], TokenAuth: ["user.read"]},
                 body: %{ref: UserRequestBody, type: :ref},
                 desc: "It's a test!",
                 headers: %{
                   "per-page" => %{
                     desc: "Total entries per page of results",
                     required: true,
                     type: :integer
                   },
                   "total" => %{desc: "Total entries to be retrieved", type: :integer}
                 },
                 id: "",
                 metadata: %{public: true},
                 path: "/api/demo",
                 path_params: %{account_id: %{type: :uuid}},
                 query_params: %{
                   id: %{default: 2, maximum: 10, minimum: 0, required: false, type: :string},
                   update: %{type: :boolean}
                 },
                 responses: %{
                   200 => %{ref: UserResponse, type: :ref},
                   201 => %{ref: PaginatedUsersResponse, type: :ref},
                   404 => %{ref: ErrorResponse, type: :ref}
                 },
                 tags: ["foo", "bar"],
                 verb: :get
               },
               %Route{
                 auth: %{JWTAuth: []},
                 headers: %{"X-Request-Id" => %{type: :string}},
                 path: "/api/demo/:id",
                 verb: :post
               },
               %Route{
                 body: %{properties: %{id: %{type: :uuid}}, type: :object},
                 headers: %{"X-Request-Id" => %{required: true, type: :uuid}},
                 path: "/api/demo/:id",
                 responses: %{200 => %{properties: %{id: %{type: :uuid}}, type: :object}},
                 verb: :put
               },
               %Route{
                 path: "/api/demo/:id",
                 verb: :delete
               },
               %Route{
                 auth: %{JWTAuth: []},
                 desc: "It's an action used for multiple routes",
                 path: "/api/multi",
                 responses: %{
                   200 => %{ref: UserResponse, type: :ref},
                   201 => %{ref: MultiResponse, type: :ref},
                   404 => %{ref: ErrorResponse, type: :ref}
                 },
                 verb: :get
               },
               %Route{
                 auth: %{JWTAuth: []},
                 desc: "It's an action used for multiple routes",
                 path: "/api/nested/:nested_id/multi",
                 path_params: %{nested_id: %{required: true, type: :uuid}},
                 responses: %{
                   200 => %{ref: UserResponse, type: :ref},
                   404 => %{ref: ErrorResponse, type: :ref}
                 },
                 verb: :get
               },
               %Route{
                 path: "/api/partials",
                 path_params: %{
                   account_id: %{type: :uuid},
                   created_at: %{type: :datetime},
                   id: %{desc: "The comment id", type: :uuid},
                   mentions: %{of: [%{type: :uuid}], type: :list},
                   team_id: %{
                     default: 2,
                     maximum: 10,
                     minimum: 0,
                     required: true,
                     type: :integer
                   },
                   text: %{type: :string}
                 },
                 query_params: %{
                   account_id: %{type: :uuid},
                   created_at: %{type: :datetime},
                   id: %{desc: "The comment id", type: :uuid},
                   mentions: %{of: [%{type: :uuid}], type: :list},
                   team_id: %{
                     default: 2,
                     maximum: 10,
                     minimum: 0,
                     required: true,
                     type: :integer
                   },
                   text: %{type: :string}
                 },
                 responses: %{200 => %{ref: UserResponse, type: :ref}},
                 verb: :get
               }
             ]
    end
  end
end
