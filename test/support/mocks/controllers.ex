defmodule Rolodex.Mocks.TestController do
  alias Rolodex.Mocks.{
    UserResponse,
    PaginatedUsersResponse,
    ErrorResponse
  }

  @doc [
    headers: %{"X-Request-Id" => %{type: :uuid, required: true}},
    # Body is using object shorthand
    body: %{
      id: :uuid,
      name: %{type: :string, desc: "The name"}
    },
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
    headers: %{"X-Request-Id" => :string}
  ]
  def conflicted(_, _), do: nil

  def undocumented(_, _), do: nil
end
