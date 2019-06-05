defmodule Rolodex.SchemaTest do
  use ExUnit.Case

  alias Rolodex.Schema

  alias Rolodex.Mocks.{
    Comment,
    NotFound,
    Parent,
    User,
    WithPartials
  }

  doctest Schema

  describe "#schema/3 macro" do
    test "It generates schema metadata" do
      assert User.__schema__(:name) == "User"
      assert User.__schema__(:desc) == "A user record"
      assert User.__schema__(:partials) == []

      assert User.__schema__(:fields) == %{
               id: %{type: :uuid, desc: "The id of the user", required: true},
               email: %{type: :string, desc: "The email of the user", required: true},
               comment: %{type: :ref, ref: Comment},
               parent: %{type: :ref, ref: Parent},
               comments: %{type: :list, of: [%{type: :ref, ref: Comment}]},
               short_comments: %{type: :list, of: [%{type: :ref, ref: Comment}]},
               comments_of_many_types: %{
                 desc: "List of text or comment",
                 type: :list,
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
               },
               private: %{type: :boolean},
               archived: %{type: :boolean},
               active: %{type: :boolean}
             }
    end
  end

  describe "#partial/1 macro" do
    test "It will collect schema refs, plain keyword lists, or plain maps for merging" do
      assert WithPartials.__schema__(:partials) |> length() == 2
      assert WithPartials.__schema__(:partials) |> Enum.at(0) == %{type: :ref, ref: Comment}

      assert WithPartials.__schema__(:partials) |> Enum.at(1) == %{
               type: :object,
               properties: %{
                 mentions: %{type: :list, of: [%{type: :uuid}]}
               }
             }
    end
  end

  describe "#to_map/1" do
    test "It serializes the schema into a Rolodex.Field struct`" do
      assert Schema.to_map(User) == %{
               type: :object,
               desc: "A user record",
               properties: %{
                 id: %{desc: "The id of the user", type: :uuid, required: true},
                 email: %{desc: "The email of the user", type: :string, required: true},
                 parent: %{type: :ref, ref: Parent},
                 comment: %{type: :ref, ref: Comment},
                 comments: %{
                   type: :list,
                   of: [%{type: :ref, ref: Comment}]
                 },
                 short_comments: %{
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
                 },
                 private: %{type: :boolean},
                 archived: %{type: :boolean},
                 active: %{type: :boolean}
               }
             }
    end

    test "It will serialize with partials merged in" do
      assert Schema.to_map(WithPartials) == %{
               type: :object,
               desc: nil,
               properties: %{
                 created_at: %{type: :datetime},
                 id: %{type: :uuid, desc: "The comment id"},
                 text: %{type: :string},
                 mentions: %{type: :list, of: [%{type: :uuid}]}
               }
             }
    end
  end

  describe "#get_refs/1" do
    test "It gets refs within a schema module" do
      refs = Schema.get_refs(User)

      assert refs == [Comment, NotFound, Parent]
    end
  end
end
