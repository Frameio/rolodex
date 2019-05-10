defmodule Rolodex.Field do
  @moduledoc """
  Shared logic for parsing parameter fields.

  `Rolodex.RequestBody`, `Rolodex.Response`, and `Rolodex.Schema` each use this
  module to parse parameter metadata. `new/1` transforms a bare map into a
  standardized parameter definition format. `get_refs/1` takes a parameter map
  returned by `new/1 and traverses it, searching for any refs to a RequestBody,
  Response, or Schema.
  """

  alias Rolodex.{Headers, RequestBody, Response, Schema}

  @type ref_type :: :headers | :request_body | :response | :schema
  @ref_types [:headers, :request_body, :response, :schema]

  @doc """
  Parses parameter data into maps with a standardized shape.

  Every field within the map returned will have a `type`. Some fields, like lists
  and objects, have other data nested within. Other fields hold references (called
  `refs`) to `Rolodex.RequestBody`, `Rolodex.Response` or `Rolodex.Schema` modules.

  You can think of the output as an AST of parameter data that a `Rolodex.Processor`
  behaviour can serialize into documentation output.

  ## Examples

  ### Parsing primitive data types (e.g. `string`)

  Valid options for a primitive are:

  - `enum` - a list of possible values
  - `desc`
  - `default`
  - `format`
  - `maximum`
  - `minimum`
  - `required`

      # Creating a simple field with a primitive type
      iex> Rolodex.Field.new(:string)
      %{type: :string}

      # With additional options
      iex> Rolodex.Field.new(type: :string, desc: "My string", enum: ["foo", "bar"])
      %{type: :string, desc: "My string", enum: ["foo", "bar"]}

  ### Parsing collections: objects and lists

      # Create an object
      iex> Rolodex.Field.new(type: :object, properties: %{id: :uuid, name: :string})
      %{
        type: :object,
        properties: %{
          id: %{type: :uuid},
          name: %{type: :string}
        }
      }

      # Shorthand for creating an object: a top-level map or keyword list
      iex> Rolodex.Field.new(%{id: :uuid, name: :string})
      %{
        type: :object,
        properties: %{
          id: %{type: :uuid},
          name: %{type: :string}
        }
      }

      # Create a list
      iex> Rolodex.Field.new(type: :list, of: [:string, :uuid])
      %{
        type: :list,
        of: [
          %{type: :string},
          %{type: :uuid}
        ]
      }

      # Shorthand for creating a list: a list of types
      iex> Rolodex.Field.new([:string, :uuid])
      %{
        type: :list,
        of: [
          %{type: :string},
          %{type: :uuid}
        ]
      }

  ### Arbitrary collections

  Use the `one_of` type to describe a field that can be one of the provided types

      iex> Rolodex.Field.new(type: :one_of, of: [:string, :uuid])
      %{
        type: :one_of,
        of: [
          %{type: :string},
          %{type: :uuid}
        ]
      }

  ### Working with refs

      iex> defmodule DemoSchema do
      ...>   use Rolodex.Schema
      ...>
      ...>   schema "DemoSchema" do
      ...>     field :id, :uuid
      ...>   end
      ...> end
      iex>
      iex> # Creating a field with a `Rolodex.Schema` as the top-level type
      iex> Rolodex.Field.new(DemoSchema)
      %{type: :ref, ref: Rolodex.FieldTest.DemoSchema}
      iex>
      iex> # Creating a collection field with various members, including a nested schema
      iex> Rolodex.Field.new(type: :list, of: [:string, DemoSchema])
      %{
        type: :list,
        of: [
          %{type: :string},
          %{type: :ref, ref: Rolodex.FieldTest.DemoSchema}
        ]
      }
  """
  @spec new(atom() | module() | list() | map()) :: map()
  def new(opts)

  def new(type) when is_atom(type), do: new(type: type)

  def new(opts) when is_list(opts) do
    case Keyword.keyword?(opts) do
      true ->
        opts
        |> Map.new()
        |> new()

      # List shorthand: if a plain list is provided, turn it into a `type: :list` field
      false ->
        new(%{type: :list, of: opts})
    end
  end

  def new(opts) when is_map(opts) and map_size(opts) == 0, do: %{}

  def new(opts) when is_map(opts), do: create_field(opts)

  defp create_field(%{type: :object, properties: props} = metadata) do
    resolved_props = Map.new(props, fn {k, v} -> {k, new(v)} end)
    %{metadata | properties: resolved_props}
  end

  defp create_field(%{type: :list, of: items} = metadata) do
    resolved_items = Enum.map(items, &new/1)
    %{metadata | of: resolved_items}
  end

  defp create_field(%{type: :one_of, of: items} = metadata) do
    resolved_items = Enum.map(items, &new/1)
    %{metadata | of: resolved_items}
  end

  defp create_field(%{type: type} = metadata) do
    cond do
      get_ref_type(type) in @ref_types -> %{type: :ref, ref: type}
      true -> metadata
    end
  end

  # Object shorthand: if a map is provided without a reserved `type: <type>`
  # identifier, turn it into a `type: :object` field
  defp create_field(data) when is_map(data) do
    new(%{type: :object, properties: data})
  end

  @doc """
  Traverses a formatted map returned by `new/1` and returns a unique list of all
  refs to `Rolodex.Response` and `Rolodex.Schema` modules within.

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
      iex> Rolodex.Field.new(type: :list, of: [TopSchema, NestedSchema])
      ...> |> Rolodex.Field.get_refs()
      [Rolodex.FieldTest.NestedSchema, Rolodex.FieldTest.TopSchema]
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

  @doc """
  Takes a module and determines if it is a known shared module ref type: Headers,
  RequestBody, Response, or Schema.
  """
  @spec get_ref_type(module()) :: ref_type() | :error
  def get_ref_type(mod) do
    cond do
      RequestBody.is_request_body_module?(mod) -> :request_body
      Response.is_response_module?(mod) -> :response
      Schema.is_schema_module?(mod) -> :schema
      Headers.is_headers_module?(mod) -> :headers
      true -> :error
    end
  end
end
