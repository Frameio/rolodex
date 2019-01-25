defmodule Rolodex.SchemaTest do
  use ExUnit.Case

  defmodule TestSchema do
    use Rolodex.Object

    object "User", type: :schema, desc: "A user record" do
      field(:id, :uuid, desc: "The id of the user")
      field(:email, :string, desc: "The email of the user")
      field(:another_thing, :string)
    end

    def another_thing(_, _), do: "hey"
  end

  describe "object" do
    test "It generates object metadata" do
      assert TestSchema.__object__(:fields) ==
               [{:id, :uuid}, {:email, :string}, {:another_thing, :string}]

      assert TestSchema.__object__(:name) == "User"
      assert TestSchema.__object__(:type) == :schema
      assert TestSchema.__object__(:desc) == "A user record"
    end
  end

  describe "field" do
    test "It generates getters" do
      assert TestSchema.id(%{a: :foo, id: :bar}, :any) == :bar
      assert TestSchema.email(%{a: :foo, email: :bar}, :any) == :bar
      assert TestSchema.another_thing(%{}, :any) == "hey"
    end

    test "You can optionally describe a field" do
      assert TestSchema.describe(:id) == "The id of the user"
      assert TestSchema.describe(:email) == "The email of the user"
      assert TestSchema.describe(:another_thing) == nil
    end
  end

  describe "to_json_schema" do
    test "It maps to json schema" do
      assert TestSchema.to_json_schema() == %{
               "User" => %{
                 "description" => "A user record",
                 "properties" => %{
                   "another_thing" => %{"type" => "string"},
                   "email" => %{"type" => "string"},
                   "id" => %{"format" => "uuid", "type" => "string"}
                 },
                 "type" => "object"
               }
             }
    end
  end
end
