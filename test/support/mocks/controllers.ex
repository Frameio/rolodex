defmodule Rolodex.Mocks.TestController do
  alias Rolodex.Mocks.{
    UserRequestBody,
    UserResponse,
    PaginatedUsersResponse,
    ErrorResponse
  }

  @doc [
    auth: [
      :JWTAuth,
      TokenAuth: ["user.read"],
      OAuth: ["user.read"]
    ],
    headers: %{"X-Request-Id" => %{type: :uuid, required: true}},
    query_params: %{
      id: %{
        type: :string,
        maximum: 10,
        minimum: 0,
        required: false,
        default: 2
      },
      update: :boolean
    },
    path_params: %{
      account_id: :uuid
    },
    body: UserRequestBody,
    responses: %{
      200 => UserResponse,
      201 => PaginatedUsersResponse,
      404 => ErrorResponse
    },
    metadata: %{public: true},
    tags: ["foo", "bar"]
  ]
  @doc "It's a test!"
  def index(_, _), do: nil

  @doc [
    multi: true,
    "/api/multi": [
      auth: :JWTAuth,
      responses: %{
        200 => UserResponse,
        404 => ErrorResponse
      }
    ],
    "/api/nested/:nested_id/multi": [
      auth: :JWTAuth,
      path_params: [
        nested_id: [type: :uuid, required: true]
      ],
      responses: %{
        200 => UserResponse,
        404 => ErrorResponse
      }
    ]
  ]
  @doc "It's an action used for multiple routes"
  def multi(_, _), do: nil

  @doc [
    auth: :JWTAuth,
    headers: %{"X-Request-Id" => :string}
  ]
  def conflicted(_, _), do: nil

  @doc [
    body: %{id: :uuid},
    responses: %{
      200 => %{id: :uuid}
    }
  ]
  def with_bare_maps(_, _), do: nil

  def undocumented(_, _), do: nil
end
