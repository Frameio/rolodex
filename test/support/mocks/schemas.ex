defmodule Rolodex.Mocks.User do
  use Rolodex.Schema

  schema "User", desc: "A user record" do
    field(:id, :uuid, desc: "The id of the user", required: true)
    field(:email, :string, desc: "The email of the user", required: true)

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