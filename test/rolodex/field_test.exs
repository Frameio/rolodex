defmodule Rolodex.FieldTest do
  use ExUnit.Case

  alias Rolodex.Field

  alias Rolodex.Mocks.{
    Comment,
    User
  }

  doctest Field

  describe "new/1" do
    test "It can create a field" do
      assert Field.new(:string) == %{type: :string}
    end

    test "It resolves top-level Rolodex.Schema refs" do
      field = Field.new(type: :list, of: [User, Comment, :string])

      assert field == %{
               type: :list,
               of: [
                 %{type: :ref, ref: User},
                 %{type: :ref, ref: Comment},
                 %{type: :string}
               ]
             }
    end

    test "It handles objects as bare maps" do
      field = Field.new(type: :object, properties: %{id: :string, nested: User})

      assert field == %{
               type: :object,
               properties: %{
                 id: %{type: :string},
                 nested: %{type: :ref, ref: User}
               }
             }
    end

    test "It handles objects with already created Fields" do
      field =
        Field.new(
          type: :object,
          properties: %{id: Field.new(:string), nested: Field.new(type: User)}
        )

      assert field == %{
               type: :object,
               properties: %{
                 id: %{type: :string},
                 nested: %{type: :ref, ref: User}
               }
             }
    end

    test "It handles object shorthand" do
      field = Field.new(id: :uuid, name: :string, nested: User)

      assert field == %{
               type: :object,
               properties: %{
                 id: %{type: :uuid},
                 name: %{type: :string},
                 nested: %{type: :ref, ref: User}
               }
             }
    end

    test "It handles list shorthand" do
      field = Field.new([:uuid, User])

      assert field == %{
               type: :list,
               of: [
                 %{type: :uuid},
                 %{type: :ref, ref: User}
               ]
             }
    end
  end

  describe "#get_refs/1" do
    test "It gets schema refs as top-level fields" do
      refs = Field.new(type: User) |> Field.get_refs()

      assert refs == [User]
    end

    test "It gets schema refs in collections" do
      refs =
        Field.new(type: :list, of: [User, Comment, :string])
        |> Field.get_refs()

      assert refs == [Comment, User]
    end

    test "It gets schema refs in nested properties" do
      refs =
        Field.new(type: :object, properties: %{id: :string, nested: User})
        |> Field.get_refs()

      assert refs == [User]
    end
  end
end
