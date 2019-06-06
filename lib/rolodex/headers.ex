defmodule Rolodex.Headers do
  @moduledoc """
  Exposes functions and macros for defining reusable headers in route doc
  annotations or responses.

  It exposes the following macros, which when used together will set up the headers:

  - `headers/2` - for declaring the headers
  - `header/3` - for declaring a single header for the set

  It also exposes the following functions:

  - `is_headers_module?/1` - determines if the provided item is a module that has
  defined a reusable headers set
  - `to_map/1` - serializes the headers module into a map
  """

  alias Rolodex.{DSL, Field}

  defmacro __using__(_) do
    quote do
      use Rolodex.DSL
      import Rolodex.Headers, only: :macros
    end
  end

  @doc """
  Opens up the headers definition for the current module. Will name the headers
  set and generate a list of header fields based on the macro calls within.

  **Accepts**
  - `name` - the headers name
  - `block` - headers shape definition

  ## Example

      defmodule SimpleHeaders do
        use Rolodex.Headers

        headers "SimpleHeaders" do
          field "X-Rate-Limited", :boolean
          field "X-Per-Page", :integer, desc: "Number of items in the response"
        end
      end
  """
  defmacro headers(name, do: block) do
    quote do
      unquote(block)

      def __headers__(:name), do: unquote(name)
      def __headers__(:headers), do: Map.new(@headers, fn {id, opts} -> {id, Field.new(opts)} end)
    end
  end

  @doc """
  Sets a header field.

  **Accepts**

  - `identifier` - the header name
  - `type` - the header field type
  - `opts` (optional) - additional metadata. See `Field.new/1` for a list of
  valid options.
  """
  defmacro field(identifier, type, opts \\ []) do
    DSL.set_field(:headers, identifier, type, opts)
  end

  @doc """
  Determines if an arbitrary item is a module that has defined a reusable headers
  set via `Rolodex.Headers` macros

  ## Example

      defmodule SimpleHeaders do
      ...>   use Rolodex.Headers
      ...>   headers "SimpleHeaders" do
      ...>     field "X-Rate-Limited", :boolean
      ...>   end
      ...> end
      iex>
      # Validating a headers module
      Rolodex.Headers.is_headers_module?(SimpleHeaders)
      true
      iex> # Validating some other module
      iex> Rolodex.Headers.is_headers_module?(OtherModule)
      false
  """
  @spec is_headers_module?(any()) :: boolean()
  def is_headers_module?(mod), do: DSL.is_module_of_type?(mod, :__headers__)

  @doc """
  Serializes the `Rolodex.Headers` metadata into a formatted map

  ## Example

      iex> defmodule SimpleHeaders do
      ...>   use Rolodex.Headers
      ...>
      ...>   headers "SimpleHeaders" do
      ...>     field "X-Rate-Limited", :boolean
      ...>     field "X-Per-Page", :integer, desc: "Number of items in the response"
      ...>   end
      ...> end
      iex>
      iex> Rolodex.Headers.to_map(SimpleHeaders)
      %{
        "X-Per-Page" => %{desc: "Number of items in the response", type: :integer},
        "X-Rate-Limited" => %{type: :boolean}
      }
  """
  @spec to_map(module()) :: map()
  def to_map(mod), do: mod.__headers__(:headers)
end
