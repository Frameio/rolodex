defmodule Rolodex.ObjectTest do
  use ExUnit.Case

  alias Rolodex.Mocks.{User, Comment}

  describe "#object/3 macro" do
    test "It generates object metadata" do
      assert User.__object__(:name) == "User"
      assert User.__object__(:desc) == "A user record"

      assert User.__object__(:fields) == [
               :id,
               :email,
               :another_thing,
               :comment,
               :comments,
               :comments_of_many_types
             ]
    end
  end

  describe "#field/3 macro" do
    test "It generates getters" do
      assert User.__field__(:id) == {:id, %{type: :uuid, desc: "The id of the user"}}
      assert User.__field__(:email) == {:email, %{type: :string, desc: "The email of the user"}}
      assert User.__field__(:another_thing) == {:another_thing, %{desc: nil, type: :string}}
      assert User.__field__(:comment) == {:comment, %{desc: nil, type: Comment}}
    end
  end

  describe "#nested_objects/0" do
    test "It returns a list of nested objects" do
      assert User.nested_objects() == [Comment]
    end
  end

  describe "#to_schema_map/0" do
    test "It translates to a schema map" do
      assert User.to_schema_map() == %{
               type: :object,
               desc: "A user record",
               properties: %{
                 id: %{desc: "The id of the user", type: :uuid},
                 email: %{desc: "The email of the user", type: :string},
                 another_thing: %{desc: nil, type: :string},
                 comment: %{
                   type: :object,
                   desc: "A comment record",
                   ref: Comment,
                   properties: %{
                     id: %{desc: "The comment id", type: :uuid},
                     text: %{desc: nil, type: :string}
                   }
                 },
                 comments: %{
                   type: :array,
                   desc: nil,
                   items: %{
                     type: :object,
                     desc: "A comment record",
                     ref: Comment,
                     properties: %{
                       id: %{desc: "The comment id", type: :uuid},
                       text: %{desc: nil, type: :string}
                     }
                   }
                 },
                 comments_of_many_types: %{
                   type: :array,
                   desc: "List of text or comment",
                   items: [
                     %{type: :string},
                     %{
                       type: :object,
                       desc: "A comment record",
                       ref: Comment,
                       properties: %{
                         id: %{desc: "The comment id", type: :uuid},
                         text: %{desc: nil, type: :string}
                       }
                     }
                   ]
                 }
               }
             }
    end
  end
end
