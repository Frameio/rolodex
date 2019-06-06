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

  alias Rolodex.DSL

  defmacro __using__(_opts) do
    quote do
      use Rolodex.DSL
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
  defmacro response(name, opts) do
    DSL.def_content_body(:__response__, name, opts)
  end

  @doc """
  Sets a description for the response
  """
  defmacro desc(str), do: DSL.set_desc(str)

  @doc """
  Sets headers to be included in the response. You can use a shared headers ref
  defined via `Rolodex.Headers`, or just pass in a bare map or keyword list. If
  the macro is called multiple times, all headers passed in will be merged together
  in the docs result.

  ## Examples

      # Shared headers module
      defmodule MyResponse do
        use Rolodex.Response

        response "MyResponse" do
          headers MyResponseHeaders
          headers MyAdditionalResponseHeaders
        end
      end

      # Headers defined in place
      defmodule MyResponse do
        use Rolodex.Response

        response "MyResponse" do
          headers %{
            "X-Pagination" => %{
              type: :integer,
              description: "Pagination information"
            }
          }
        end
      end
  """
  defmacro headers(metadata), do: DSL.set_headers(metadata)

  @doc """
  Defines a response shape for the given content type key

  **Accepts**
  - `key` - a valid content-type key
  - `block` - metadata about the response shape for this content type
  """
  defmacro content(key, opts) do
    DSL.def_content_type_shape(:__response__, key, opts)
  end

  @doc """
  Sets an example for the content type. This macro can be used multiple times
  within a content type block to allow multiple examples.

  **Accepts**
  - `name` - a name for the example
  - `body` - a map, which is the example data
  """
  defmacro example(name, example_body) do
    DSL.set_example(:__response__, name, example_body)
  end

  @doc """
  Sets a schema for the current response content type. There are three ways
  you can define a schema for a content-type chunk:

  1. You can pass in an alias for a reusable schema defined via `Rolodex.Schema`
  2. You can define a schema inline via the same macro syntax used in `Rolodex.Schema`
  3. You can define a schema inline via a bare map, which will be parsed with `Rolodex.Field`

  ## Examples

      # Via a reusable schema alias
      content "application/json" do
        schema MySchema
      end

      # Can define a schema inline via the schema + field + partial macros
      content "application/json" do
        schema do
          field :id, :uuid
          field :name, :string, desc: "The name"

          partial PaginationParams
        end
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
  defmacro schema(mod), do: DSL.set_schema(:__response__, mod)

  @doc """
  Sets a collection of schemas for the current response content type.

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
  defmacro schema(collection_type, opts) do
    DSL.set_schema(:__response__, collection_type, opts)
  end

  @doc """
  Adds a new field to the schema when defining a schema inline via macros. See
  `Rolodex.Field` for more information about valid field metadata.

  Accepts
  - `identifier` - field name
  - `type` - either an atom or another Rolodex.Schema module
  - `opts` - a keyword list of options, looks for `desc` and `of` (for array types)

  ## Example

      defmodule MyResponse do
        use Rolodex.Response

        response "MyResponse" do
          content "application/json" do
            schema do
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
        end
      end
  """
  defmacro field(identifier, type, opts \\ []) do
    DSL.set_field(:fields, identifier, type, opts)
  end

  @doc """
  Adds a new partial to the schema when defining a schema inline via macros. A
  partial is another schema that will be serialized and merged into the top-level
  properties map for the current schema. Partials are useful for shared parameters
  used across multiple schemas. Bare keyword lists and maps that are parseable
  by `Rolodex.Field` are also supported.

  ## Example

      defmodule PaginationParams do
        use Rolodex.Schema

        schema "PaginationParams" do
          field :page, :integer
          field :page_size, :integer
          field :total_pages, :integer
        end
      end

      defmodule MyResponse do
        use Rolodex.Response

        response "MyResponse" do
          content "application/json" do
            schema do
              field :id, :uuid
              partial PaginationParams
            end
          end
        end
      end
  """
  defmacro partial(mod), do: DSL.set_partial(mod)

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
  def is_response_module?(mod), do: DSL.is_module_of_type?(mod, :__response__)

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
      ...>     headers %{"X-Rate-Limited" => :boolean}
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
        headers: [
          %{"X-Rate-Limited" => %{type: :boolean}}
        ],
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
  def to_map(mod), do: DSL.to_content_body_map(&mod.__response__/1)

  @doc """
  Traverses a serialized Response and collects any nested references to any
  Schemas within. See `Rolodex.Field.get_refs/1` for more info.
  """
  @spec get_refs(module()) :: [module()]
  def get_refs(mod), do: DSL.get_refs_in_content_body(&mod.__response__/1)
end
