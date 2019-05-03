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

  alias Rolodex.Field

  defmacro __using__(_opts) do
    quote do
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
        end
      end
  """
  defmacro schema(name, opts \\ [], do: block) do
    quote do
      Module.register_attribute(__MODULE__, :fields, accumulate: true)

      unquote(block)

      def __schema__(:name), do: unquote(name)
      def __schema__(:desc), do: unquote(Keyword.get(opts, :desc, nil))
      def __schema__(:fields), do: @fields |> Enum.reverse()
    end
  end

  @doc """
  Adds a new field to the schema. Will generate a method `__field__/1` where the
  one argument is the field `identifier`. This can be used to fetch the field
  metadata later.

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

          # A field that is one of the possible provided types
          field :any, :one_of, of: [:string, OtherSchema]
        end
      end
  """
  defmacro field(identifier, type, opts \\ []) do
    quote do
      @fields unquote(identifier)

      def __field__(unquote(identifier)) do
        field = ([type: unquote(type)] ++ unquote(opts)) |> Field.new()
        {unquote(identifier), field}
      end
    end
  end

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
  def is_schema_module?(item)

  def is_schema_module?(module) when is_atom(module) do
    try do
      module.__info__(:functions)
      |> Keyword.has_key?(:__schema__)
    rescue
      # Any error means that `module` isn't a module and so we can just say `false`
      _ -> false
    end
  end

  def is_schema_module?(_), do: false

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
  def to_map(schema) do
    desc = schema.__schema__(:desc)

    props =
      schema.__schema__(:fields)
      |> Map.new(&schema.__field__/1)

    Field.new(type: :object, properties: props, desc: desc)
  end

  @doc """
  Traverses a serialized Schema and collects any nested references to other
  Schemas within. See `Rolodex.Field.get_refs/1` for more info.
  """
  @spec get_refs(module()) :: [module()]
  def get_refs(schema) do
    schema
    |> to_map()
    |> Field.get_refs()
  end
end
