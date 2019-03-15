defmodule Rolodex.Mocks.UserRequestBody do
  use Rolodex.RequestBody
  alias Rolodex.Mocks.User

  request_body "UserRequestBody" do
    desc("A single user entity request body")

    content "application/json" do
      schema(User)
      example(:request, %{id: "1"})
    end
  end
end

defmodule Rolodex.Mocks.UsersRequestBody do
  use Rolodex.RequestBody
  alias Rolodex.Mocks.User

  request_body "UsersRequestBody" do
    desc("A list of user entities")

    content "application/json" do
      schema([User])
      example(:request, [%{id: "1"}])
    end
  end
end

defmodule Rolodex.Mocks.ParentsRequestBody do
  use Rolodex.RequestBody
  alias Rolodex.Mocks.Parent

  request_body "ParentsRequestBody" do
    desc("A list of parent entities")

    content "application/json" do
      schema(:list, of: [Parent])
    end
  end
end

defmodule Rolodex.Mocks.PaginatedUsersRequestBody do
  use Rolodex.RequestBody
  alias Rolodex.Mocks.User

  request_body "PaginatedUsersRequestBody" do
    desc("A paginated list of user entities")

    content "application/json" do
      schema(%{
        total: :integer,
        page: :integer,
        users: [User]
      })

      example(:request, [%{id: "1"}])
    end
  end
end

defmodule Rolodex.Mocks.MultiRequestBody do
  use Rolodex.RequestBody
  alias Rolodex.Mocks.{Comment, User}

  request_body "MultiRequestBody" do
    content "application/json" do
      schema(User)
    end

    content "application/lolsob" do
      schema([Comment])
    end
  end
end
