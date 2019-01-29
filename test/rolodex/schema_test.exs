defmodule Rolodex.SchemaTest do
  use ExUnit.Case

  alias Rolodex.Mocks.User

  describe "object" do
    test "It generates object metadata" do
      assert User.__object__(:fields) ==
               [{:id, :uuid}, {:email, :string}, {:another_thing, :string}]

      assert User.__object__(:name) == "User"
      assert User.__object__(:type) == :schema
      assert User.__object__(:desc) == "A user record"
    end
  end

  describe "field" do
    test "It generates getters" do
      assert User.id(%{a: :foo, id: :bar}, :any) == :bar
      assert User.email(%{a: :foo, email: :bar}, :any) == :bar
      assert User.another_thing(%{}, :any) == "hey"
    end

    test "You can optionally describe a field" do
      assert User.describe(:id) == "The id of the user"
      assert User.describe(:email) == "The email of the user"
      assert User.describe(:another_thing) == nil
    end
  end

  describe "to_json_schema" do
    test "It maps to json schema" do
      assert User.to_json_schema() == %{
               "description" => "A user record",
               "properties" => %{
                 "another_thing" => %{"type" => "string"},
                 "email" => %{"type" => "string"},
                 "id" => %{"format" => "uuid", "type" => "string"}
               },
               "type" => "object"
             }
    end
  end
end
