defmodule Rolodex.Mocks.TestRouter do
  use Phoenix.Router

  scope "/api", Rolodex.Mocks do
    get("/demo", TestController, :index)
    post("/demo/:id", TestController, :conflicted)
  end
end

defmodule Rolodex.Mocks.TestController do
  alias Rolodex.Mocks.User

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
      200 => User,
      # 201 is using list shorthand
      201 => [User],
      404 => %{
        type: :object,
        properties: %{
          status: :integer,
          message: :string
        }
      }
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

defmodule Rolodex.Mocks.User do
  use Rolodex.Schema

  schema "User", desc: "A user record" do
    field(:id, :uuid, desc: "The id of the user")
    field(:email, :string, desc: "The email of the user")

    # Nested object
    field(:comment, Rolodex.Mocks.Comment)

    # Nested schema with a cyclical dependency
    field(:parent, Rolodex.Mocks.Parent)

    # List of one type
    field(:comments, :list, of: [Rolodex.Mocks.Comment])

    # List of multiple types
    field(:comments_of_many_types, :list,
      of: [:string, Rolodex.Mocks.Comment],
      desc: "List of text or comment"
    )

    # A field with multiple possible types
    field(:multi, :one_of, of: [:string, Rolodex.Mocks.NotFound])
  end
end

defmodule Rolodex.Mocks.Parent do
  use Rolodex.Schema

  schema "Parent" do
    field(:child, Rolodex.Mocks.User)
  end
end

defmodule Rolodex.Mocks.Comment do
  use Rolodex.Schema

  schema "Comment", desc: "A comment record" do
    field(:id, :uuid, desc: "The comment id")
    field(:text, :string)
  end
end

defmodule Rolodex.Mocks.NotFound do
  use Rolodex.Schema

  schema "NotFound", desc: "Not found response" do
    field(:message, :string)
  end
end

defmodule Rolodex.Mocks.NestedDemo do
  use Rolodex.Schema

  schema "NestedDemo" do
    field(:nested, Rolodex.Mocks.FirstNested)
  end
end

defmodule Rolodex.Mocks.FirstNested do
  use Rolodex.Schema

  schema "FirstNested" do
    field(:nested, Rolodex.Mocks.SecondNested)
  end
end

defmodule Rolodex.Mocks.SecondNested do
  use Rolodex.Schema

  schema "SecondNested" do
    field(:id, :uuid)
  end
end
