defmodule Rolodex.Schema do
  @moduledoc """
  Exposes functions and macros for defining reusable parameter schemas.

  It includes two macros. Used together, you can setup a reusable schema:

  - `schema/3` - for declaring a schema
  - `field/3` - for declaring schema fields

  It also exposes the following functions:

  - `is_schema_module?/1` - determines if the provided item is a module that has
  defined a reuseable schema
  - `to_map/1` - serializes a schema module into a map for use by a `Rolodex.Processor`
  behaviour
  - `get_refs/1` - traverses a schema and searches for any nested schemas within
  """

  alias Rolodex.{DSL, Field}

  defmacro __using__(_opts) do
    quote do
      use Rolodex.DSL
      import Rolodex.Schema
    end
  end

  @doc """
  Opens up the schema definition for the current module. Will name the schema
  and generate metadata for the schema based on subsequent calls to `field/3`

  **Accepts**
  - `name` - the schema name
  - `opts` - a keyword list of options (currently, only looks for a `desc` key)
  - `block` - the inner schema definition with one or more calls to `field/3`

  ## Example

      defmodule MySchema do
        use Rolodex.Schema

        schema "MySchema", desc: "Example schema" do
          # Atomic field with no description
          field :id, :uuid

          # Atomic field with a description
          field :name, :string, desc: "The object's name"

          # A field that refers to another, nested object
          field :other, OtherSchema

          # A field that is an array of items of one-or-more types
          field :multi, :list, of: [:string, OtherSchema]

          # A field that is one of the possible provided types
          field :any, :one_of, of: [:string, OtherSchema]

          # Treats OtherSchema as a partial to be merged into this schema
          partial OtherSchema
        end
      end
  """
  defmacro schema(name, opts \\ [], do: block) do
    schema_body_ast = DSL.set_schema(:__schema__, do: block)

    quote do
      unquote(schema_body_ast)

      def __schema__(:name), do: unquote(name)
      def __schema__(:desc), do: unquote(Keyword.get(opts, :desc, nil))
    end
  end

  @doc """
  Adds a new field to the schema. See `Rolodex.Field` for more information about
  valid field metadata.

  Accepts
  - `identifier` - field name
  - `type` - either an atom or another Rolodex.Schema module
  - `opts` - a keyword list of options, looks for `desc` and `of` (for array types)

  ## Example

      defmodule MySchema do
        use Rolodex.Schema

        schema "MySchema", desc: "Example schema" do
          # Atomic field with no description
          field :id, :uuid

          # Atomic field with a description
          field :name, :string, desc: "The object's name"

          # A field that refers to another, nested object
          field :other, OtherSchema

          # A field that is an array of items of one-or-more types
          field :multi, :list, of: [:string, OtherSchema]

          # You can use a shorthand to define a list field, the below is identical
          # to the above
          field :multi, [:string, OtherSchema]

          # A field that is one of the possible provided types
          field :any, :one_of, of: [:string, OtherSchema]
        end
      end
  """
  defmacro field(identifier, type, opts \\ []) do
    DSL.set_field(:fields, identifier, type, opts)
  end

  @doc """
  Adds a new partial to the schema. A partial is another schema that will be
  serialized and merged into the top-level properties map for the current schema.
  Partials are useful for shared parameters used across multiple schemas. Bare
  keyword lists and maps that are parseable by `Rolodex.Field` are also supported.

  ## Example

      defmodule AgeSchema do
        use Rolodex.Schema

        schema "AgeSchema" do
          field :age, :integer
          field :date_of_birth, :datetime
          field :city_of_birth, :string
        end
      end

      defmodule MySchema do
        use Rolodex.Schema

        schema "MySchema" do
          field :id, :uuid
          field :name, :string

          # A partial via another schema
          partial AgeSchema

          # A partial via a bare keyword list
          partial [
            city: :string,
            state: :string,
            country: :string
          ]
        end
      end

      # MySchema will be serialized by `to_map/1` as:
      %{
        type: :object,
        desc: nil,
        properties: %{
          id: %{type: :uuid},
          name: %{type: :string},

          # From the AgeSchema partial
          age: %{type: :integer},
          date_of_birth: %{type: :datetime}
          city_of_birth: %{type: :string},

          # From the keyword list partial
          city: %{type: :string},
          state: %{type: :string},
          country: %{type: :string}
        }
      }
  """
  defmacro partial(mod), do: DSL.set_partial(mod)

  @doc """
  Determines if an arbitrary item is a module that has defined a reusable schema
  via `Rolodex.Schema` macros

  ## Example

      iex> defmodule SimpleSchema do
      ...>   use Rolodex.Schema
      ...>   schema "SimpleSchema", desc: "Demo schema" do
      ...>     field :id, :uuid
      ...>   end
      ...> end
      iex>
      iex> # Validating a schema module
      iex> Rolodex.Schema.is_schema_module?(SimpleSchema)
      true
      iex> # Validating some other module
      iex> Rolodex.Schema.is_schema_module?(OtherModule)
      false
  """
  @spec is_schema_module?(any()) :: boolean()
  def is_schema_module?(mod), do: DSL.is_module_of_type?(mod, :__schema__)

  @doc """
  Serializes the `Rolodex.Schema` metadata into a formatted map.

  ## Example

      iex> defmodule OtherSchema do
      ...>   use Rolodex.Schema
      ...>
      ...>   schema "OtherSchema" do
      ...>     field :id, :uuid
      ...>   end
      ...> end
      iex>
      iex> defmodule MySchema do
      ...>   use Rolodex.Schema
      ...>
      ...>   schema "MySchema", desc: "An example" do
      ...>     # Atomic field with no description
      ...>     field :id, :uuid
      ...>
      ...>     # Atomic field with a description
      ...>     field :name, :string, desc: "The schema's name"
      ...>
      ...>     # A field that refers to another, nested object
      ...>     field :other, OtherSchema
      ...>
      ...>     # A field that is an array of items of one-or-more types
      ...>     field :multi, :list, of: [:string, OtherSchema]
      ...>
      ...>     # A field that is one of the possible provided types
      ...>     field :any, :one_of, of: [:string, OtherSchema]
      ...>   end
      ...> end
      iex>
      iex> Rolodex.Schema.to_map(MySchema)
      %{
        type: :object,
        desc: "An example",
        properties: %{
          id: %{type: :uuid},
          name: %{desc: "The schema's name", type: :string},
          other: %{type: :ref, ref: Rolodex.SchemaTest.OtherSchema},
          multi: %{
            type: :list,
            of: [
              %{type: :string},
              %{type: :ref, ref: Rolodex.SchemaTest.OtherSchema}
            ]
          },
          any: %{
            type: :one_of,
            of: [
              %{type: :string},
              %{type: :ref, ref: Rolodex.SchemaTest.OtherSchema}
            ]
          }
        }
      }
  """
  @spec to_map(module()) :: map()
  def to_map(mod) do
    mod.__schema__({nil, :schema})
    |> Map.put(:desc, mod.__schema__(:desc))
  end

  @doc """
  Traverses a serialized Schema and collects any nested references to other
  Schemas within. See `Rolodex.Field.get_refs/1` for more info.
  """
  @spec get_refs(module()) :: [module()]
  def get_refs(mod) do
    mod
    |> to_map()
    |> Field.get_refs()
  end
end
