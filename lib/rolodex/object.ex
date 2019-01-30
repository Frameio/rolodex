defmodule Rolodex.Object do
  @moduledoc """
  Macros for defining Rolodex objects, which are primarily used to describe
  response schemas.

  It includes two macros:

  * `object/3` for declaring an object
  * `field/3` for declaring object fields

  Used together, they will set up the following method on the using module:

  * `to_schema_map/0` - translates object definition into a bare map to be used
  by a `Rolodex.Processor` behaviour for serialization into destination JSON
  * `nested_objects/0` - gets any nested objects within the field definitions
  * `__field__/1` - to fetch metadata about each defined field on the object
  * `__object__/1` - to introspect on the object, valid arguments are: `:name`,
  `:desc`, and `:fields`

  ## Example

    defmodule MyObject do
      use Rolodex.Object

      object "MyObject", desc: "An example" do
        # Atomic field with no description
        field :id, :uuid

        # Atomic field with a description
        field :name, :string, desc: "The object's name"

        # A field that refers to another, nested object
        field :other, OtherObject

        # A field that is an array of items, all the same type
        field :strings, :array, of: :string

        # A field that is an array of items of one-or-more types
        field :multi, :array, of: [:string, OtherObject]
      end
    end

    defmodule OtherObject do
      use Rolodex.Object

      object "OtherObject" do
        field :id, :uuid
      end
    end

    # Then, `nested_objects/0` will return a list of any nested objects in the fields
    iex> MyObject.nested_objects()
    [OtherObject]

    # Then, `to_schema_map/0` can be used to serialize the object definition
    iex> MyObject.to_schema_map()
    %{
      type: :object,
      desc: "An example",
      properties: %{
        id: %{desc: nil, type: :uuid},
        name: %{desc: "The object's name", type: :string},
        other: %{
          type: :object,
          desc: nil,
          # Nested objects include a ref attribute
          ref: OtherObject
          properties: %{
            id: %{desc: nil, type: :uuid}
          }
        },
        strings: %{
          type: :array,
          desc: nil,
          items: %{type: :string}
        },
        multi: %{
          type: :array,
          desc: :nil,
          items: [
            %{type: :string},
            %{
              type: :object,
              desc: nil,
              ref: OtherObject
              properties: %{
                id: %{desc: nil, type: :uuid}
              }
            }
          ]
        }
      }
    }
  """

  @valid_field_opts [:desc, :of]
  @default_field_opts [desc: nil]

  defmacro __using__(_opts) do
    quote do
      import Rolodex.Object, only: :macros
    end
  end

  @doc """
  Opens up the object definition for the current module. Will name the object
  and generate metadata for the object based on subsequent calls to `field/3`

  Accepts
  * `name` - the object name
  * `opts` - a keyword list of options (currently, only looks for a `desc` key)
  * `block` - the inner object definition with one or more calls to `field/3`
  """
  defmacro object(name, opts \\ [], do: block) do
    quote do
      Module.register_attribute(__MODULE__, :fields, accumulate: true)

      unquote(block)

      def __object__(:name), do: unquote(name)
      def __object__(:desc), do: unquote(Keyword.get(opts, :desc, nil))
      def __object__(:fields), do: @fields |> Enum.reverse()

      def to_schema_map() do
        %{
          type: :object,
          desc: __MODULE__.__object__(:desc),
          properties:
            __MODULE__.__object__(:fields) |> Rolodex.Object.object_properties(__MODULE__)
        }
      end

      def nested_objects() do
        __MODULE__.__object__(:fields)
        |> Rolodex.Object.get_nested_objects(__MODULE__)
      end
    end
  end

  @doc """
  Adds a new field to the object. Will generate a method `__field__/1` where the
  one argument is the field `identifier`. This can be used to fetch the field
  metadata later.

  Accepts
  * `identifier` - field name
  * `type` - either an atom or another module with a Rolodex.Object definition
  * `opts` - a keyword list of options, looks for `desc` and `of` (for array types)
  """
  defmacro field(identifier, type, opts \\ []) do
    valid_field_opts = @valid_field_opts
    default_field_opts = @default_field_opts

    # TODO(billyc): It'd be great if we could use `bind_quoted` here, but I don't
    # think we can. I personally run into function undefined errors when binding
    # and then referencing variables witin the quote block.
    #
    # It looks like this is/was a known issue with nested quotes (affecting us
    # since this quote block will be invoked within the `object/3` macro's quote
    # block). v1.8.0 released "fix", but I still see the issue there.
    #
    # Issue: https://github.com/elixir-lang/elixir/issues/7709
    # Fix: https://github.com/elixir-lang/elixir/pull/8042
    quote do
      @fields unquote(identifier)

      def __field__(unquote(identifier)) do
        # %{type: <type>}, plus any valid metadata from `opts`
        field_metadata =
          unquote(default_field_opts)
          |> Map.new()
          |> Map.merge(
            unquote(opts)
            |> Keyword.take(unquote(valid_field_opts))
            |> Map.new()
          )
          |> Map.merge(%{type: unquote(type)})

        {unquote(identifier), field_metadata}
      end
    end
  end

  @doc """
  Examines each object field and generates a map representing the field. Collects
  this data into a map keyed by each field's name.
  """
  @spec object_properties([atom() | binary()], module()) :: map()
  def object_properties(fields, mod) do
    fields
    |> Map.new(fn field_name ->
      field_name
      |> mod.__field__()
      |> properties_for_field()
    end)
  end

  defp properties_for_field({field_name, %{type: :array, of: item_types, desc: desc}})
       when is_list(item_types) do
    array_items =
      item_types
      |> Enum.map(fn type -> resolve_field_type(%{type: type}) end)

    {field_name, %{type: :array, items: array_items, desc: desc}}
  end

  defp properties_for_field({field_name, %{type: :array, of: item_type, desc: desc}}) do
    array_item = resolve_field_type(%{type: item_type})

    {field_name, %{type: :array, items: array_item, desc: desc}}
  end

  defp properties_for_field({field_name, metadata}) do
    {field_name, resolve_field_type(metadata)}
  end

  defp resolve_field_type(%{type: type} = metadata) do
    case Rolodex.Utils.can_generate_schema?(type) do
      true ->
        type.to_schema_map() |> Map.merge(%{ref: type})

      false ->
        metadata
    end
  end

  @doc """
  Examines each object field and collects any nested objects into a deduplicated list
  """
  @spec get_nested_objects([atom() | binary()], module()) :: [module()]
  def get_nested_objects(fields, mod) do
    fields
    |> Enum.reduce([], fn field_name, nested ->
      field_name
      |> mod.__field__()
      |> nested_objects_for_field(nested)
    end)
  end

  defp nested_objects_for_field({_, %{type: :array, of: items}}, nested)
       when is_list(items) do
    items
    |> Enum.reduce(nested, fn item, acc -> update_nested(acc, item) end)
  end

  defp nested_objects_for_field({_, %{type: :array, of: item}}, nested),
    do: update_nested(nested, item)

  defp nested_objects_for_field({_, %{type: type}}, nested),
    do: update_nested(nested, type)

  defp update_nested(nested, item) do
    case Rolodex.Utils.can_generate_schema?(item) && item not in nested do
      true -> nested ++ [item]
      false -> nested
    end
  end
end
