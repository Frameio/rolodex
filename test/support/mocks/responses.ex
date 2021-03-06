defmodule Rolodex.Mocks.UserResponse do
  use Rolodex.Response
  alias Rolodex.Mocks.{User, RateLimitHeaders}

  response "UserResponse" do
    desc("A single user entity response")
    headers(RateLimitHeaders)

    content "application/json" do
      schema(User)
      example(:response, %{id: "1"})
    end
  end
end

defmodule Rolodex.Mocks.UsersResponse do
  use Rolodex.Response

  alias Rolodex.Mocks.{PaginationHeaders, User}

  response "UsersResponse" do
    desc("A list of user entities")
    headers(PaginationHeaders)

    content "application/json" do
      schema([User])
      example(:response, [%{id: "1"}])
    end
  end
end

defmodule Rolodex.Mocks.ParentsResponse do
  use Rolodex.Response
  alias Rolodex.Mocks.Parent

  response "ParentsResponse" do
    desc("A list of parent entities")

    headers(%{
      "total" => :integer,
      "per-page" => %{type: :integer, required: true}
    })

    content "application/json" do
      schema(:list, of: [Parent])
    end
  end
end

defmodule Rolodex.Mocks.PaginatedUsersResponse do
  use Rolodex.Response
  alias Rolodex.Mocks.{PaginationHeaders, User}

  response "PaginatedUsersResponse" do
    desc("A paginated list of user entities")
    headers(PaginationHeaders)

    content "application/json" do
      schema(%{
        total: :integer,
        page: :integer,
        users: [User]
      })

      example(:response, [%{id: "1"}])
    end
  end
end

defmodule Rolodex.Mocks.ErrorResponse do
  use Rolodex.Response

  response "ErrorResponse" do
    desc("An error response")

    content "application/json" do
      schema(%{
        status: :integer,
        message: :string
      })
    end
  end
end

defmodule Rolodex.Mocks.MultiResponse do
  use Rolodex.Response

  alias Rolodex.Mocks.{
    Comment,
    PaginationHeaders,
    RateLimitHeaders,
    User
  }

  response "MultiResponse" do
    headers(PaginationHeaders)
    headers(RateLimitHeaders)

    content "application/json" do
      schema(User)
    end

    content "application/lolsob" do
      schema([Comment])
    end
  end
end

defmodule Rolodex.Mocks.InlineMacroSchemaResponse do
  use Rolodex.Response

  alias Rolodex.Mocks.Comment

  response "InlineMacroSchemaResponse" do
    content "application/json" do
      schema do
        field(:created_at, :datetime)

        partial(Comment)
        partial(mentions: [:uuid])
      end
    end
  end
end
