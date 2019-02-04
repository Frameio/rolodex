defmodule Rolodex.SchemaTest do
  use ExUnit.Case

  alias Rolodex.Schema

  alias Rolodex.Mocks.{
    Comment,
    NotFound,
    Parent,
    User
  }

  doctest Rolodex.Schema

  describe "#schema/3 macro" do
    test "It generates schema metadata" do
      assert User.__schema__(:name) == "User"
      assert User.__schema__(:desc) == "A user record"

      assert User.__schema__(:fields) == [
               :id,
               :email,
               :comment,
               :parent,
               :comments,
               :comments_of_many_types,
               :multi
             ]
    end
  end

  describe "#field/3 macro" do
    test "It generates getters" do
      assert User.__field__(:id) == {:id, %{type: :uuid, desc: "The id of the user"}}

      assert User.__field__(:email) == {:email, %{type: :string, desc: "The email of the user"}}

      assert User.__field__(:comment) == {:comment, %{type: :ref, ref: Comment}}
      assert User.__field__(:parent) == {:parent, %{type: :ref, ref: Parent}}

      assert User.__field__(:comments) ==
               {:comments, %{type: :list, of: [%{type: :ref, ref: Comment}]}}

      assert User.__field__(:comments_of_many_types) ==
               {:comments_of_many_types,
                %{
                  desc: "List of text or comment",
                  type: :list,
                  of: [
                    %{type: :string},
                    %{type: :ref, ref: Comment}
                  ]
                }}

      assert User.__field__(:multi) ==
               {:multi,
                %{
                  type: :one_of,
                  of: [
                    %{type: :string},
                    %{type: :ref, ref: NotFound}
                  ]
                }}
    end
  end

  describe "#to_map/1" do
    test "It serializes the schema into a Rolodex.Field struct`" do
      assert Schema.to_map(User) == %{
               type: :object,
               desc: "A user record",
               properties: %{
                 id: %{desc: "The id of the user", type: :uuid},
                 email: %{desc: "The email of the user", type: :string},
                 parent: %{type: :ref, ref: Parent},
                 comment: %{type: :ref, ref: Comment},
                 comments: %{
                   type: :list,
                   of: [%{type: :ref, ref: Comment}]
                 },
                 comments_of_many_types: %{
                   type: :list,
                   desc: "List of text or comment",
                   of: [
                     %{type: :string},
                     %{type: :ref, ref: Comment}
                   ]
                 },
                 multi: %{
                   type: :one_of,
                   of: [
                     %{type: :string},
                     %{type: :ref, ref: NotFound}
                   ]
                 }
               }
             }
    end
  end

  describe "#new_field/1" do
    test "It can create a field" do
      assert Schema.new_field(:string) == %{type: :string}
    end

    test "It resolves top-level Rolodex.Schema refs" do
      field = Schema.new_field(type: :list, of: [User, Comment, :string])

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
      field = Schema.new_field(type: :object, properties: %{id: :string, nested: User})

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
        Schema.new_field(
          type: :object,
          properties: %{id: Schema.new_field(:string), nested: Schema.new_field(type: User)}
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
      field = Schema.new_field(id: :uuid, name: :string, nested: User)

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
      field = Schema.new_field([:uuid, User])

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
    test "It gets refs within a schema module" do
      refs = Schema.get_refs(User)

      assert refs == [Comment, NotFound, Parent]
    end

    test "It gets schema refs as top-level fields" do
      refs = Schema.new_field(type: User) |> Schema.get_refs()

      assert refs == [User]
    end

    test "It gets schema refs in collections" do
      refs =
        Schema.new_field(type: :list, of: [User, Comment, :string])
        |> Schema.get_refs()

      assert refs == [Comment, User]
    end

    test "It gets schema refs in nested properties" do
      refs =
        Schema.new_field(type: :object, properties: %{id: :string, nested: User})
        |> Schema.get_refs()

      assert refs == [User]
    end
  end
end
