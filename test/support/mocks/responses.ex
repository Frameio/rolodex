defmodule Rolodex.Mocks.UserResponse do
  use Rolodex.Response
  alias Rolodex.Mocks.User

  response "UserResponse" do
    desc("A single user entity response")

    content "application/json" do
      schema(User)
      example(:response, %{id: "1"})
    end
  end
end

defmodule Rolodex.Mocks.UsersResponse do
  use Rolodex.Response
  alias Rolodex.Mocks.User

  response "UsersResponse" do
    desc("A list of user entities")

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

    content "application/json" do
      schema(:list, of: [Parent])
    end
  end
end

defmodule Rolodex.Mocks.PaginatedUsersResponse do
  use Rolodex.Response
  alias Rolodex.Mocks.User

  response "PaginatedUsersResponse" do
    desc("A paginated list of user entities")

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
  alias Rolodex.Mocks.{Comment, User}

  response "MultiResponse" do
    content "application/json" do
      schema(User)
    end

    content "application/lolsob" do
      schema([Comment])
    end
  end
end
