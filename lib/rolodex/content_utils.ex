defmodule Rolodex.ContentUtils do
  @moduledoc false

  alias Rolodex.Field

  def def_content_body(type, name, do: block) do
    quote do
      Module.register_attribute(__MODULE__, :content_types, accumulate: true)
      Module.register_attribute(__MODULE__, :current_content_type, accumulate: false)
      Module.register_attribute(__MODULE__, :body_description, accumulate: false)
      Module.register_attribute(__MODULE__, :headers, accumulate: true)

      @body_description nil

      unquote(block)

      Module.delete_attribute(__MODULE__, :current_content_type)

      def unquote(type)(:name), do: unquote(name)
      def unquote(type)(:desc), do: @body_description
      def unquote(type)(:headers), do: @headers |> Enum.reverse()
      def unquote(type)(:content_types), do: @content_types |> Enum.reverse()
    end
  end

  def set_desc(str) do
    quote do
      @body_description unquote(str)
    end
  end

  def set_headers({:__aliases__, _, _} = mod) do
    quote do
      @headers Field.new(unquote(mod))
    end
  end

  def set_headers(headers) do
    quote do
      @headers unquote(headers) |> Map.new(fn {header, opts} -> {header, Field.new(opts)} end)
    end
  end

  def def_content_type_shape(type, key, do: block) do
    quote do
      Module.register_attribute(__MODULE__, :examples, accumulate: true)

      @content_types unquote(key)
      @current_content_type unquote(key)

      unquote(block)

      def unquote(type)({unquote(key), :examples}), do: @examples |> Enum.reverse()

      Module.delete_attribute(__MODULE__, :examples)
    end
  end

  def set_example(type, name, example_body) do
    quote do
      @examples unquote(name)

      def unquote(type)({@current_content_type, :examples, unquote(name)}),
        do: unquote(example_body)
    end
  end

  def set_schema(type, mods) when is_list(mods) do
    quote do
      def unquote(type)({@current_content_type, :schema}) do
        Field.new(type: :list, of: unquote(mods))
      end
    end
  end

  def set_schema(type, mod) do
    quote do
      def unquote(type)({@current_content_type, :schema}) do
        Field.new(unquote(mod))
      end
    end
  end

  def set_schema(type, collection_type, of: mods) do
    quote do
      def unquote(type)({@current_content_type, :schema}) do
        Field.new(type: unquote(collection_type), of: unquote(mods))
      end
    end
  end

  def set_field(attr, identifier, type, opts) do
    quote do
      Module.put_attribute(
        __MODULE__,
        unquote(attr),
        {unquote(identifier), [type: unquote(type)] ++ unquote(opts)}
      )
    end
  end

  def is_module_of_type?(mod, type) when is_atom(mod) do
    try do
      mod.__info__(:functions) |> Keyword.has_key?(type)
    rescue
      _ -> false
    end
  end

  def is_module_of_type?(_), do: false

  def to_map(fun) do
    %{
      desc: fun.(:desc),
      headers: fun.(:headers),
      content: serialize_content(fun)
    }
  end

  defp serialize_content(fun) do
    fun.(:content_types)
    |> Map.new(fn content_type ->
      data = %{
        schema: fun.({content_type, :schema}),
        examples: serialize_examples(fun, content_type)
      }

      {content_type, data}
    end)
  end

  defp serialize_examples(fun, content_type) do
    fun.({content_type, :examples})
    |> Map.new(&{&1, fun.({content_type, :examples, &1})})
  end

  def get_refs(fun) do
    fun
    |> to_map()
    |> Map.take([:headers, :content])
    |> collect_refs(MapSet.new())
    |> Enum.to_list()
  end

  def collect_refs(data, refs) do
    refs
    |> set_headers_ref(data)
    |> set_content_refs(data)
  end

  defp set_headers_ref(refs, %{headers: []}), do: refs

  defp set_headers_ref(refs, %{headers: headers}),
    do: Enum.reduce(headers, refs, &collect_headers_refs/2)

  defp collect_headers_refs(%{type: :ref, ref: ref}, refs), do: MapSet.put(refs, ref)
  defp collect_headers_refs(_, refs), do: refs

  defp set_content_refs(refs, %{content: content}) do
    Enum.reduce(content, refs, fn {_, %{schema: schema}}, acc ->
      schema
      |> Field.get_refs()
      |> MapSet.new()
      |> MapSet.union(acc)
    end)
  end
end
