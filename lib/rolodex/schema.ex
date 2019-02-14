defmodule Rolodex.Schema do
  @moduledoc """
  Exposes functions and macros for working with request and response parameters.

  It includes two macros. Used together, they will setup reuseable schemas
  for things like API responses.

  - `schema/3` - for declaring a schema
  - `field/3` - for declaring schema fields

  It also exposes the following functions:

  - `is_schema_module?/1` - determines if the provided item is a module that has
  defined a reuseable schema
  - `to_map/1` - serializes a schema module into a map for use by a `Rolodex.Processor`
  behaviour
  - `new_field/1` - parses a schema field into a map of metadata. The `field/3`
  macro uses this function to parse the metadata passed in. This function is also
  called when parsing all controller action `@doc` parameter annotations
  - `get_refs/1` - takes a schema or map and traverses it, looking for any nested
  references to schemas within
  """

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
        field = ([type: unquote(type)] ++ unquote(opts)) |> new_field()
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
  Serializes the `Rolodex.Schema` metadata defined for the given module into an
  object, using the `new_field/1` helper.

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

    new_field(type: :object, properties: props, desc: desc)
  end

  @doc """
  Parses data for schema fields and controller action parameter annotations.
  Resolves references to any nested `Rolodex.Schema` modules within. Generates
  a new map representing the field in a standardized format.

  Every field within the map returned will have a `type`. Some fields, like lists
  and objects, have other data nested within. Other fields hold references (called
  `refs`) to `Rolodex.Schema` modules.

  You can think of the output as an AST of parameter data that a `Rolodex.Processor`
  behaviour can accept for writing out to a destination.

  ## Examples

  ### Parsing primitive data types (e.g. `string`)

      # Creating a simple field with a primitive type
      iex> Rolodex.Schema.new_field(:string)
      %{type: :string}

      # With additional options
      iex> Rolodex.Schema.new_field(type: :string, desc: "My string")
      %{type: :string, desc: "My string"}

  ### Parsing collections: objects and lists

      # Create an object
      iex> Rolodex.Schema.new_field(type: :object, properties: %{id: :uuid, name: :string})
      %{
        type: :object,
        properties: %{
          id: %{type: :uuid},
          name: %{type: :string}
        }
      }

      # Shorthand for creating an object: a top-level map or keyword list
      iex> Rolodex.Schema.new_field(%{id: :uuid, name: :string})
      %{
        type: :object,
        properties: %{
          id: %{type: :uuid},
          name: %{type: :string}
        }
      }

      # Create a list
      iex> Rolodex.Schema.new_field(type: :list, of: [:string, :uuid])
      %{
        type: :list,
        of: [
          %{type: :string},
          %{type: :uuid}
        ]
      }

      # Shorthand for creating a list: a list of types
      iex> Rolodex.Schema.new_field([:string, :uuid])
      %{
        type: :list,
        of: [
          %{type: :string},
          %{type: :uuid}
        ]
      }

  ### Arbitrary collections

  Use the `one_of` type to describe a field that can be one of the provided types

      iex> Rolodex.Schema.new_field(type: :one_of, of: [:string, :uuid])
      %{
        type: :one_of,
        of: [
          %{type: :string},
          %{type: :uuid}
        ]
      }

  ### Working with schemas

      iex> defmodule DemoSchema do
      ...>   use Rolodex.Schema
      ...>
      ...>   schema "DemoSchema" do
      ...>     field :id, :uuid
      ...>   end
      ...> end
      iex>
      iex> # Creating a field with a `Rolodex.Schema` as the top-level type
      iex> Rolodex.Schema.new_field(DemoSchema)
      %{type: :ref, ref: Rolodex.SchemaTest.DemoSchema}
      iex>
      iex> # Creating a collection field with various members, including a nested schema
      iex> Rolodex.Schema.new_field(type: :list, of: [:string, DemoSchema])
      %{
        type: :list,
        of: [
          %{type: :string},
          %{type: :ref, ref: Rolodex.SchemaTest.DemoSchema}
        ]
      }
  """
  @spec new_field(atom() | module() | list() | map()) :: map()
  def new_field(opts)

  def new_field(type) when is_atom(type), do: new_field(type: type)

  def new_field(opts) when is_list(opts) do
    case Keyword.keyword?(opts) do
      true ->
        opts
        |> Map.new()
        |> new_field()

      # List shorthand: if a plain list is provided, turn it into a `type: :list` field
      false ->
        new_field(%{type: :list, of: opts})
    end
  end

  def new_field(opts) when is_map(opts), do: create_field(opts)

  defp create_field(%{type: :object, properties: props} = metadata) do
    resolved_props = Map.new(props, fn {k, v} -> {k, new_field(v)} end)
    %{metadata | properties: resolved_props}
  end

  defp create_field(%{type: :list, of: items} = metadata) do
    resolved_items = Enum.map(items, &new_field/1)
    %{metadata | of: resolved_items}
  end

  defp create_field(%{type: :one_of, of: items} = metadata) do
    resolved_items = Enum.map(items, &new_field/1)
    %{metadata | of: resolved_items}
  end

  defp create_field(%{type: type} = metadata) do
    case is_schema_module?(type) do
      true -> Map.merge(metadata, %{type: :ref, ref: type})
      false -> metadata
    end
  end

  # Object shorthand: if a map is provided without a reserved `type: <type>`
  # identifier, turn it into a `type: :object` field
  defp create_field(data) when is_map(data) do
    new_field(%{type: :object, properties: data})
  end

  @doc """
  Returns a unique list of all nested `Rolodex.Schema` refs within the current field
  map or schema module.

  ## Examples

      iex> defmodule NestedSchema do
      ...>   use Rolodex.Schema
      ...>
      ...>   schema "NestedSchema" do
      ...>     field :id, :uuid
      ...>   end
      ...> end
      iex>
      iex> defmodule TopSchema do
      ...>   use Rolodex.Schema
      ...>
      ...>   schema "TopSchema", desc: "An example" do
      ...>     # Atomic field with no description
      ...>     field :id, :uuid
      ...>
      ...>     # Atomic field with a description
      ...>     field :name, :string, desc: "The schema's name"
      ...>
      ...>     # A field that refers to another, nested object
      ...>     field :other, NestedSchema
      ...>
      ...>     # A field that is an array of items of one-or-more types
      ...>     field :multi, :list, of: [:string, NestedSchema]
      ...>
      ...>     # A field that is one of the possible provided types
      ...>     field :any, :one_of, of: [:string, NestedSchema]
      ...>   end
      ...> end
      iex>
      iex> # Searching for refs in a formatted map
      iex> Rolodex.Schema.new_field(type: :list, of: [TopSchema, NestedSchema])
      ...> |> Rolodex.Schema.get_refs()
      [Rolodex.SchemaTest.NestedSchema, Rolodex.SchemaTest.TopSchema]
      iex>
      iex> # Searching for refs in an arbitrary map
      iex> Rolodex.Schema.get_refs(%{id: :uuid, nested: TopSchema})
      [Rolodex.SchemaTest.NestedSchema]
      iex>
      iex> # Search for refs in a schema
      iex> Rolodex.Schema.get_refs(TopSchema)
      [Rolodex.SchemaTest.NestedSchema]
  """
  @spec get_refs(module() | map()) :: [module()]
  def get_refs(field)

  def get_refs(%{of: items}) when is_list(items) do
    items
    |> Enum.reduce(MapSet.new(), &collect_refs_for_item/2)
    |> Enum.to_list()
  end

  def get_refs(%{type: :object, properties: props}) when is_map(props) do
    props
    |> Enum.reduce(MapSet.new(), fn {_, item}, refs -> collect_refs_for_item(item, refs) end)
    |> Enum.to_list()
  end

  def get_refs(%{type: :ref, ref: object}) when is_atom(object) do
    [object]
  end

  def get_refs(field) when is_map(field) do
    field
    |> Enum.reduce(MapSet.new(), fn {_, value}, refs -> collect_refs_for_item(value, refs) end)
    |> Enum.to_list()
  end

  def get_refs(schema) when is_atom(schema) do
    case is_schema_module?(schema) do
      true ->
        schema
        |> to_map()
        |> get_refs()

      false ->
        []
    end
  end

  def get_refs(_), do: []

  defp collect_refs_for_item(item, refs) do
    case get_refs(item) do
      [] ->
        refs

      objects ->
        objects
        |> MapSet.new()
        |> MapSet.union(refs)
    end
  end
end
