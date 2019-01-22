defprotocol API.Web.Cereal do
  @doc """
  Translates a struct into json through the defined schema
  """
  def to_json(item)
end

defmodule InvalidObjectTypeError do
  defexception message: "Invalid schema type"
end

defmodule InvalidMimeTypeError do
  defexception message: "Invalid mime type"
end

defmodule Swag.Object do
  @json_mapping %{
    uuid: %{"type" => "string", "format" => "uuid"},
    email: %{"type" => "string", "format" => "email"},
    string: %{"type" => "string"}
  }

  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :fields, accumulate: true)
      Module.register_attribute(__MODULE__, :documentation, accumulate: true)

      import unquote(__MODULE__), only: :macros

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    fields = Module.get_attribute(env.module, :fields) |> Enum.reverse()
    documentation = Module.get_attribute(env.module, :documentation) |> Enum.reverse()

    func_ast = compile_functions(fields)
    struct_ast = define_struct(fields)
    docs_ast = compile_documentation(documentation)

    quote do
      def __object__(:fields), do: unquote(fields)
      unquote(func_ast)
      unquote(struct_ast)
      unquote(docs_ast)

      def to_json_schema() do
        %{
          __MODULE__.__object__(:name) => %{
            "type" => "object",
            "description" => __MODULE__.__object__(:desc),
            "properties" =>
              Map.new(unquote(fields), fn {k, v} ->
                {Atom.to_string(k), Swag.Object.to_json_type(v)}
              end)
          }
        }
      end
    end
  end

  defmacro object(name, opts \\ [], do: block) do
    type = get_object_type(opts)

    quote do
      def __object__(:type), do: unquote(type)
      def __object__(:name), do: unquote(name)
      def __object__(:desc), do: unquote(Keyword.get(opts, :desc, nil))
      unquote(block)
    end
  end

  defmacro field(identifier, type, opts \\ []) do
    quote bind_quoted: [identifier: identifier, type: type, opts: opts] do
      @fields {identifier, type}
      @documentation {identifier, Keyword.get(opts, :desc, nil)}
    end
  end

  def compile_functions(fields) do
    for {identifier, _type} <- fields do
      quote do
        def unquote(identifier)(m, _), do: Map.get(m, unquote(identifier))
        defoverridable [{unquote(identifier), 2}]
      end
    end
  end

  def define_struct(fields) do
    quote do
      defstruct unquote(fields)
    end
  end

  def compile_documentation(docs \\ []) do
    for {identifier, doc} <- docs do
      quote do
        def describe(unquote(identifier)), do: unquote(doc)
      end
    end
  end

  def to_json_type(v) do
    Map.get(@json_mapping, v)
  end

  defp get_object_type(opts) do
    Keyword.get(opts, :type, :schema)
    |> validate_object_type()
  end

  defp validate_object_type(type) when type in [:schema], do: type
  defp validate_object_type(_), do: raise(InvalidObjectTypeError)
end
