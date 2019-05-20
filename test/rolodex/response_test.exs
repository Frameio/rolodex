defmodule Rolodex.ResponseTest do
  use ExUnit.Case

  alias Rolodex.Response

  alias Rolodex.Mocks.{
    UserResponse,
    UsersResponse,
    PaginatedUsersResponse,
    RateLimitHeaders,
    ParentsResponse,
    MultiResponse,
    User,
    Comment,
    Parent,
    PaginationHeaders
  }

  doctest Response

  describe "#response/2 macro" do
    test "It sets the expected getter functions" do
      assert UserResponse.__response__(:name) == "UserResponse"
      assert UserResponse.__response__(:content_types) == ["application/json"]
    end
  end

  describe "#desc/1 macro" do
    test "It sets the expected getter function" do
      assert UserResponse.__response__(:desc) == "A single user entity response"
    end

    test "Description is not required" do
      assert MultiResponse.__response__(:desc) == nil
    end
  end

  describe "#set_headers/1 macro" do
    test "It handles a shared headers module" do
      assert UsersResponse.__response__(:headers) == [
               %{
                 type: :ref,
                 ref: PaginationHeaders
               }
             ]
    end

    test "It handles a bare map or kwl" do
      assert ParentsResponse.__response__(:headers) == [
               %{
                 "total" => %{type: :integer},
                 "per-page" => %{type: :integer, required: true}
               }
             ]
    end

    test "It handles multiple headers" do
      assert MultiResponse.__response__(:headers) == [
               %{
                 type: :ref,
                 ref: PaginationHeaders
               },
               %{
                 type: :ref,
                 ref: RateLimitHeaders
               }
             ]
    end
  end

  describe "#content/2 macro" do
    test "It sets the expected getter function" do
      assert UserResponse.__response__({"application/json", :examples}) == [:response]
    end
  end

  describe "#example/2 macro" do
    test "It sets the expected getter function" do
      assert UserResponse.__response__({"application/json", :examples, :response}) == %{id: "1"}
    end
  end

  describe "#schema/1 macro" do
    test "It handles a schema module" do
      assert UserResponse.__response__({"application/json", :schema}) == %{
               type: :ref,
               ref: User
             }
    end

    test "It handles a list" do
      assert UsersResponse.__response__({"application/json", :schema}) == %{
               type: :list,
               of: [%{type: :ref, ref: User}]
             }
    end

    test "It handles a bare map" do
      assert PaginatedUsersResponse.__response__({"application/json", :schema}) == %{
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
  end

  describe "#schema/2 macro" do
    test "It handles a list" do
      assert ParentsResponse.__response__({"application/json", :schema}) == %{
               type: :list,
               of: [%{type: :ref, ref: Parent}]
             }
    end
  end

  describe "#is_response_module?/2" do
    test "It detects if the module has defined a response via the macros" do
      assert Response.is_response_module?(UserResponse)
      assert !Response.is_response_module?(User)
    end
  end

  describe "#to_map/1" do
    test "It serializes the response as expected" do
      assert Response.to_map(PaginatedUsersResponse) == %{
               desc: "A paginated list of user entities",
               headers: [
                 %{
                   type: :ref,
                   ref: PaginationHeaders
                 }
               ],
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
                     response: [%{id: "1"}]
                   }
                 }
               }
             }
    end
  end

  describe "#get_refs/1" do
    test "It gets refs within a response module" do
      assert Response.get_refs(MultiResponse) == [
               Comment,
               PaginationHeaders,
               RateLimitHeaders,
               User
             ]
    end
  end
end
