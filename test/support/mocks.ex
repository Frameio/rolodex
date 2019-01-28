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

  def undocumented(_, _), do: nil
end

defmodule Rolodex.Mocks.User do
  use Rolodex.Object

  object "User", type: :schema, desc: "A user record" do
    field(:id, :uuid, desc: "The id of the user")
    field(:email, :string, desc: "The email of the user")
    field(:another_thing, :string)
  end

  def another_thing(_, _), do: "hey"
end

defmodule Rolodex.Mocks.NotFound do
  use Rolodex.Object

  object "NotFound", type: :schema, desc: "Not found response" do
    field(:message, :string)
  end
end
