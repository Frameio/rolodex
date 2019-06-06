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

  alias Rolodex.DSL

  defmacro __using__(_opts) do
    quote do
      use Rolodex.DSL
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
    DSL.def_content_body(:__request_body__, name, opts)
  end

  @doc """
  Sets a description for the request body
  """
  defmacro desc(str), do: DSL.set_desc(str)

  @doc """
  Defines a request body shape for the given content type key

  **Accepts**
  - `key` - a valid content-type key
  - `block` - metadata about the request body shape for this content type
  """
  defmacro content(key, opts) do
    DSL.def_content_type_shape(:__request_body__, key, opts)
  end

  @doc """
  Sets an example for the content type. This macro can be used multiple times
  within a content type block to allow multiple examples.

  **Accepts**
  - `name` - a name for the example
  - `body` - a map, which is the example data
  """
  defmacro example(name, example_body) do
    DSL.set_example(:__request_body__, name, example_body)
  end

  @doc """
  Sets a schema for the current request body content type. There are three ways
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
  defmacro schema(mod), do: DSL.set_schema(:__request_body__, mod)

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
    DSL.set_schema(:__request_body__, collection_type, opts)
  end

  @doc """
  Adds a new field to the schema when defining a schema inline via macros. See
  `Rolodex.Field` for more information about valid field metadata.

  Accepts
  - `identifier` - field name
  - `type` - either an atom or another Rolodex.Schema module
  - `opts` - a keyword list of options, looks for `desc` and `of` (for array types)

  ## Example

      defmodule MyRequestBody do
        use Rolodex.RequestBody

        request_body "MyRequestBody" do
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

      defmodule MyRequestBody do
        use Rolodex.RequestBody

        request_body "MyRequestBody" do
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
  def is_request_body_module?(mod), do: DSL.is_module_of_type?(mod, :__request_body__)

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
        headers: [],
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
  def to_map(mod), do: DSL.to_content_body_map(&mod.__request_body__/1)

  @doc """
  Traverses a serialized Request Body and collects any nested references to any
  Schemas within. See `Rolodex.Field.get_refs/1` for more info.
  """
  @spec get_refs(module()) :: [module()]
  def get_refs(mod), do: DSL.get_refs_in_content_body(&mod.__request_body__/1)
end
