defmodule Rolodex.RequestBodyTest do
  use ExUnit.Case

  alias Rolodex.RequestBody

  alias Rolodex.Mocks.{
    UserRequestBody,
    UsersRequestBody,
    PaginatedUsersRequestBody,
    ParentsRequestBody,
    MultiRequestBody,
    User,
    Comment,
    Parent,
    InlineMacroSchemaRequest
  }

  doctest RequestBody

  describe "#request_body/2 macro" do
    test "It sets the expected getter functions" do
      assert UserRequestBody.__request_body__(:name) == "UserRequestBody"
      assert UserRequestBody.__request_body__(:content_types) == ["application/json"]
    end
  end

  describe "#desc/1 macro" do
    test "It sets the expected getter function" do
      assert UserRequestBody.__request_body__(:desc) == "A single user entity request body"
    end

    test "Description is not required" do
      assert MultiRequestBody.__request_body__(:desc) == nil
    end
  end

  describe "#content/2 macro" do
    test "It sets the expected getter function" do
      assert UserRequestBody.__request_body__({"application/json", :examples}) == [:request]
    end
  end

  describe "#example/2 macro" do
    test "It sets the expected getter function" do
      assert UserRequestBody.__request_body__({"application/json", :examples, :request}) == %{
               id: "1"
             }
    end
  end

  describe "#schema/1 macro" do
    test "It handles a schema module" do
      assert UserRequestBody.__request_body__({"application/json", :schema}) == %{
               type: :ref,
               ref: User
             }
    end

    test "It handles a list" do
      assert UsersRequestBody.__request_body__({"application/json", :schema}) == %{
               type: :list,
               of: [%{type: :ref, ref: User}]
             }
    end

    test "It handles a bare map" do
      assert PaginatedUsersRequestBody.__request_body__({"application/json", :schema}) == %{
               type: :object,
               properties: %{
                 total: %{type: :integer},
                 page: %{type: :integer},
                 users: %{
                   type: :list,
                   of: [%{type: :ref, ref: User}]
                 }
               }
             }
    end

    test "It handles an inline macro" do
      assert InlineMacroSchemaRequest.__request_body__({"application/json", :schema}) == %{
               type: :object,
               properties: %{
                 created_at: %{type: :datetime},
                 id: %{type: :uuid, desc: "The comment id"},
                 text: %{type: :string},
                 mentions: %{type: :list, of: [%{type: :uuid}]}
               }
             }
    end
  end

  describe "#schema/2 macro" do
    test "It handles a list" do
      assert ParentsRequestBody.__request_body__({"application/json", :schema}) == %{
               type: :list,
               of: [%{type: :ref, ref: Parent}]
             }
    end
  end

  describe "#is_request_body_module?/2" do
    test "It detects if the module has defined a request body via the macros" do
      assert RequestBody.is_request_body_module?(UserRequestBody)
      assert !RequestBody.is_request_body_module?(User)
    end
  end

  describe "#to_map/1" do
    test "It serializes the request body as expected" do
      assert RequestBody.to_map(PaginatedUsersRequestBody) == %{
               desc: "A paginated list of user entities",
               headers: [],
               content: %{
                 "application/json" => %{
                   schema: %{
                     type: :object,
                     properties: %{
                       total: %{type: :integer},
                       page: %{type: :integer},
                       users: %{
                         type: :list,
                         of: [%{type: :ref, ref: User}]
                       }
                     }
                   },
                   examples: %{
                     request: [%{id: "1"}]
                   }
                 }
               }
             }
    end
  end

  describe "#get_refs/1" do
    test "It gets refs within a request body module" do
      assert RequestBody.get_refs(MultiRequestBody) == [Comment, User]
    end
  end
end
