defmodule Rolodex.Response do
  @moduledoc """
  Exposes functions and macros for defining reusable responses.

  It exposes the following macros, which when used together will setup a response:

  - `response/2` - for declaring a response
  - `desc/1` - for setting an (optional) response description
  - `content/2` - for defining a response shape for a specific content type
  - `schema/1` and `schema/2` - for defining the shape for a content type
  - `example/2` - for defining an (optional) response example for a content type

  It also exposes the following functions:

  - `is_response_module?/1` - determines if the provided item is a module that
  has defined a reusable response
  - `to_map/1` - serializes a response module into a map
  - `get_refs/1` - traverses a response and searches for any nested `Rolodex.Schema`
  refs within
  """

  alias Rolodex.Field

  defmacro __using__(_opts) do
    quote do
      import Rolodex.Response, only: :macros
    end
  end

  @doc """
  Opens up the response definition for the current module. Will name the response
  and generate metadata for the response based on macro calls within the provided
  block.

  **Accept**
  - `name` - the response name
  - `block` - response shape definitions

  ## Example

      defmodule MyResponse do
        use Rolodex.Response

        response "MyResponse" do
          desc "A demo response with multiple content types"

          content "application/json" do
            schema MyResponseSchema

            example :response, %{foo: "bar"}
            example :other_response, %{bar: "baz"}
          end

          content "foo/bar" do
            schema AnotherResponseSchema
            example :response, %{foo: "bar"}
          end
        end
      end
  """
  defmacro response(name, do: block) do
    quote do
      Module.register_attribute(__MODULE__, :content_types, accumulate: true)
      Module.register_attribute(__MODULE__, :current_content_type, accumulate: false)
      Module.register_attribute(__MODULE__, :response_desc, accumulate: false)

      @response_desc nil

      unquote(block)

      Module.delete_attribute(__MODULE__, :current_content_type)

      def __response__(:name), do: unquote(name)
      def __response__(:desc), do: @response_desc
      def __response__(:content_types), do: @content_types |> Enum.reverse()
    end
  end

  @doc """
  Sets a description for the response
  """
  defmacro desc(str) do
    quote do
      @response_desc unquote(str)
    end
  end

  @doc """
  Defines a response shape for the given content type key

  **Accepts**
  - `key` - a valid content-type key
  - `block` - metadata about the response shape for this content type
  """
  defmacro content(key, do: block) do
    quote do
      Module.register_attribute(__MODULE__, :examples, accumulate: true)

      @content_types unquote(key)
      @current_content_type unquote(key)

      unquote(block)

      def __response__({unquote(key), :examples}), do: @examples |> Enum.reverse()

      Module.delete_attribute(__MODULE__, :examples)
    end
  end

  @doc """
  Sets an example for the content type. This macro can be used multiple times
  within a content type block to allow multiple examples.

  **Accepts**
  - `name` - a name for the example
  - `body` - a map, which is the example data
  """
  defmacro example(name, body) do
    quote do
      @examples unquote(name)

      def __response__({@current_content_type, :examples, unquote(name)}), do: unquote(body)
    end
  end

  @doc """
  Sets a schema for the current response content type. Data passed into to the
  schema/1 macro will be parsed by `Rolodex.Field.new/1`.

  ## Examples

      # Response is a list, where each item is a MySchema
      content "application/json" do
        schema [MySchema]
      end

      # Response is a MySchema
      content "application/json" do
        content MySchema
      end

      # Can provide a bare map, which will be parsed via `Rolodex.Field`
      content "application/json" do
        schema %{
          type: :object,
          properties: %{
            id: :uuid,
            name: :string
          }
        }
      end
  """
  defmacro schema(mod_or_mods)

  defmacro schema(mods) when is_list(mods) do
    quote do
      def __response__({@current_content_type, :schema}) do
        Field.new(type: :list, of: unquote(mods))
      end
    end
  end

  defmacro schema(mod) do
    quote do
      def __response__({@current_content_type, :schema}) do
        Field.new(unquote(mod))
      end
    end
  end

  @doc """
  Sets a schema of a collection type.

  ## Examples

      # Response is a list
      content "application/json" do
        schema :list, of: [MySchema]
      end

      # Response is one of the provided types
      content "application/json" do
        schema :one_of, of: [MySchema, MyOtherSchema]
      end
  """
  defmacro schema(collection_type, of: mods) do
    quote do
      def __response__({@current_content_type, :schema}) do
        Field.new(type: unquote(collection_type), of: unquote(mods))
      end
    end
  end

  @doc """
  Determines if an arbitrary item is a module that has defined a reusable response
  via `Rolodex.Response` macros

  ## Example

      iex> defmodule SimpleResponse do
      ...>   use Rolodex.Response
      ...>   response "SimpleResponse" do
      ...>     content "application/json" do
      ...>       schema MySchema
      ...>     end
      ...>   end
      ...> end
      iex>
      iex> # Validating a response module
      iex> Rolodex.Response.is_response_module?(SimpleResponse)
      true
      iex> # Validating some other module
      iex> Rolodex.Response.is_response_module?(OtherModule)
      false
  """
  @spec is_response_module?(any()) :: boolean()
  def is_response_module?(item)

  def is_response_module?(mod) when is_atom(mod) do
    try do
      mod.__info__(:functions)
      |> Keyword.has_key?(:__response__)
    rescue
      _ -> false
    end
  end

  def is_response_module?(_), do: false

  @doc """
  Serializes the `Rolodex.Response` metadata into a formatted map.

  ## Example

      iex> defmodule MySimpleSchema do
      ...>   use Rolodex.Schema
      ...>
      ...>   schema "MySimpleSchema" do
      ...>     field :id, :uuid
      ...>   end
      ...> end
      iex>
      iex> defmodule MyResponse do
      ...>   use Rolodex.Response
      ...>
      ...>   response "MyResponse" do
      ...>     desc "A demo response"
      ...>
      ...>     content "application/json" do
      ...>       schema MySimpleSchema
      ...>       example :response, %{id: "123"}
      ...>     end
      ...>
      ...>     content "application/json-list" do
      ...>       schema [MySimpleSchema]
      ...>       example :response, [%{id: "123"}]
      ...>       example :another_response, [%{id: "234"}]
      ...>     end
      ...>   end
      ...> end
      iex>
      iex> Rolodex.Response.to_map(MyResponse)
      %{
        desc: "A demo response",
        content: %{
          "application/json" => %{
            examples: %{
              response: %{id: "123"}
            },
            schema: %{
              type: :ref,
              ref: Rolodex.ResponseTest.MySimpleSchema
            }
          },
          "application/json-list" => %{
            examples: %{
              response: [%{id: "123"}],
              another_response: [%{id: "234"}],
            },
            schema: %{
              type: :list,
              of: [
                %{type: :ref, ref: Rolodex.ResponseTest.MySimpleSchema}
              ]
            }
          }
        }
      }
  """
  @spec to_map(module()) :: map()
  def to_map(resp) do
    %{
      desc: resp.__response__(:desc),
      content: serialize_content(resp)
    }
  end

  defp serialize_content(resp) do
    resp.__response__(:content_types)
    |> Map.new(fn content_type ->
      data = %{
        schema: resp.__response__({content_type, :schema}),
        examples: serialize_examples(resp, content_type)
      }

      {content_type, data}
    end)
  end

  defp serialize_examples(resp, content_type) do
    {content_type, :examples}
    |> resp.__response__()
    |> Map.new(&{&1, resp.__response__({content_type, :examples, &1})})
  end

  @doc """
  Traverses a serialized Response and collects any nested references to any
  Schemas within. See `Rolodex.Field.get_refs/1` for more info.
  """
  @spec get_refs(module()) :: [module()]
  def get_refs(response) do
    response
    |> to_map()
    |> Map.get(:content)
    |> Enum.reduce(MapSet.new(), fn {_, %{schema: schema}}, acc ->
      schema
      |> Field.get_refs()
      |> MapSet.new()
      |> MapSet.union(acc)
    end)
    |> Enum.to_list()
  end
end
