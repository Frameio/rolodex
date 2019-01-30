defmodule Rolodex.Mocks.TestController do
  @doc [
    headers: %{foo: :bar},
    body: %{foo: :bar},
    query_params: %{"foo" => "bar"},
    responses: %{200 => Rolodex.Mocks.User},
    metadata: %{public: true},
    tags: ["foo", "bar"]
  ]
  @doc "It's a test!"
  def index(_, _), do: nil

  @doc [
    headers: %{foo: :baz}
  ]
  def conflicted(_, _), do: nil

  def undocumented(_, _), do: nil
end

defmodule Rolodex.Mocks.User do
  use Rolodex.Object

  object "User", desc: "A user record" do
    field(:id, :uuid, desc: "The id of the user")
    field(:email, :string, desc: "The email of the user")

    # Field w/ an ignored option
    field(:another_thing, :string, invalid: :opt)

    # Nested object
    field(:comment, Rolodex.Mocks.Comment)

    # Array of one type
    field(:comments, :array, of: Rolodex.Mocks.Comment)

    # Array of multiple types
    field(:comments_of_many_types, :array,
      of: [:string, Rolodex.Mocks.Comment],
      desc: "List of text or comment"
    )
  end
end

defmodule Rolodex.Mocks.Comment do
  use Rolodex.Object

  object "Comment", desc: "A comment record" do
    field(:id, :uuid, desc: "The comment id")
    field(:text, :string)
  end
end

defmodule Rolodex.Mocks.NotFound do
  use Rolodex.Object

  object "NotFound", desc: "Not found response" do
    field(:message, :string)
  end
end
