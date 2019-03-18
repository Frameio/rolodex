defmodule Rolodex.RequestBody do
  @moduledoc """
  Exposes functions and macros for defining reusable request bodies.

  It exposes the following macros, which when used together will setup a request body:

  - `request_body/2` - for declaring a request body
  - `desc/1` - for setting an (optional) request body description
  - `content/2` - for defining a request body shape for a specific content type
  - `schema/1` and `schema/2` - for defining the shape for a content type
  - `example/2` - for defining an (optional) request body example for a content type

  It also exposes the following functions:

  - `is_request_body_module?/1` - determines if the provided item is a module that
  has defined a reusable request body
  - `to_map/1` - serializes a request body module into a map
  - `get_refs/1` - traverses a request body and searches for any nested
  `Rolodex.Schema` refs within
  """

  alias Rolodex.ContentUtils

  defmacro __using__(_opts) do
    quote do
      import Rolodex.RequestBody, only: :macros
    end
  end

  @doc """
  Opens up the request body definition for the current module. Will name the
  request body and generate metadata for the request body based on macro calls
  within the provided block.

  **Accept**
  - `name` - the request body name
  - `block` - request body shape definitions

  ## Example

      defmodule MyRequestBody do
        use Rolodex.RequestBody

        request_body "MyRequestBody" do
          desc "A demo request body with multiple content types"

          content "application/json" do
            schema MyRequestBodySchema

            example :request_body, %{foo: "bar"}
            example :other_request_body, %{bar: "baz"}
          end

          content "foo/bar" do
            schema AnotherRequestBodySchema
            example :request_body, %{foo: "bar"}
          end
        end
      end
  """
  defmacro request_body(name, opts) do
    ContentUtils.def_content_body(:__request_body__, name, opts)
  end

  @doc """
  Sets a description for the request body
  """
  defmacro desc(str) do
    ContentUtils.set_desc(str)
  end

  @doc """
  Defines a request body shape for the given content type key

  **Accepts**
  - `key` - a valid content-type key
  - `block` - metadata about the request body shape for this content type
  """
  defmacro content(key, opts) do
    ContentUtils.def_content_type_shape(:__request_body__, key, opts)
  end

  @doc """
  Sets an example for the content type. This macro can be used multiple times
  within a content type block to allow multiple examples.

  **Accepts**
  - `name` - a name for the example
  - `body` - a map, which is the example data
  """
  defmacro example(name, example_body) do
    ContentUtils.set_example(:__request_body__, name, example_body)
  end

  @doc """
  Sets a schema for the current request body content type. Data passed into to
  the schema/1 macro will be parsed by `Rolodex.Field.new/1`.

  ## Examples

      # Request body is a list, where each item is a MySchema
      content "application/json" do
        schema [MySchema]
      end

      # Request body is a MySchema
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
  defmacro schema(mod) do
    ContentUtils.set_schema(:__request_body__, mod)
  end

  @doc """
  Sets a schema of a collection type.

  ## Examples

      # Request body is a list
      content "application/json" do
        schema :list, of: [MySchema]
      end

      # Request body is one of the provided types
      content "application/json" do
        schema :one_of, of: [MySchema, MyOtherSchema]
      end
  """
  defmacro schema(collection_type, opts) do
    ContentUtils.set_schema(:__request_body__, collection_type, opts)
  end

  @doc """
  Determines if an arbitrary item is a module that has defined a reusable
  request body via `Rolodex.RequestBody` macros.

  ## Example

      iex> defmodule SimpleRequestBody do
      ...>   use Rolodex.RequestBody
      ...>
      ...>   request_body "SimpleRequestBody" do
      ...>     content "application/json" do
      ...>       schema MySchema
      ...>     end
      ...>   end
      ...> end
      iex>
      iex> # Validating a request body module
      iex> Rolodex.RequestBody.is_request_body_module?(SimpleRequestBody)
      true
      iex> # Validating some other module
      iex> Rolodex.RequestBody.is_request_body_module?(OtherModule)
      false
  """
  @spec is_request_body_module?(any()) :: boolean()
  def is_request_body_module?(mod), do: ContentUtils.is_module_of_type?(mod, :__request_body__)

  @doc """
  Serializes the `Rolodex.RequestBody` metadata into a formatted map.

  ## Example

      iex> defmodule MySimpleSchema do
      ...>   use Rolodex.Schema
      ...>
      ...>   schema "MySimpleSchema" do
      ...>     field :id, :uuid
      ...>   end
      ...> end
      iex>
      iex> defmodule MyRequestBody do
      ...>   use Rolodex.RequestBody
      ...>
      ...>   request_body "MyRequestBody" do
      ...>     desc "A demo request body"
      ...>
      ...>     content "application/json" do
      ...>       schema MySimpleSchema
      ...>       example :request_body, %{id: "123"}
      ...>     end
      ...>
      ...>     content "application/json-list" do
      ...>       schema [MySimpleSchema]
      ...>       example :request_body, [%{id: "123"}]
      ...>       example :another_request_body, [%{id: "234"}]
      ...>     end
      ...>   end
      ...> end
      iex>
      iex> Rolodex.RequestBody.to_map(MyRequestBody)
      %{
        desc: "A demo request body",
        content: %{
          "application/json" => %{
            examples: %{
              request_body: %{id: "123"}
            },
            schema: %{
              type: :ref,
              ref: Rolodex.RequestBodyTest.MySimpleSchema
            }
          },
          "application/json-list" => %{
            examples: %{
              request_body: [%{id: "123"}],
              another_request_body: [%{id: "234"}],
            },
            schema: %{
              type: :list,
              of: [
                %{type: :ref, ref: Rolodex.RequestBodyTest.MySimpleSchema}
              ]
            }
          }
        }
      }
  """
  @spec to_map(module()) :: map()
  def to_map(mod), do: ContentUtils.to_map(&mod.__request_body__/1)

  @doc """
  Traverses a serialized Request Body and collects any nested references to any
  Schemas within. See `Rolodex.Field.get_refs/1` for more info.
  """
  @spec get_refs(module()) :: [module()]
  def get_refs(mod), do: ContentUtils.get_refs(&mod.__request_body__/1)
end
