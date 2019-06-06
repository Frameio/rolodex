defmodule Rolodex.DSL do
  @moduledoc false

  alias Rolodex.{Field, Schema}

  # Sets the various shared module attributes used in DSL macros to collect
  # metadata definitions
  defmacro __using__(_) do
    quote do
      # Used in various macro helpers
      alias Rolodex.Field

      # Used to collect content body (requests, responses) metadata
      Module.register_attribute(__MODULE__, :content_types, accumulate: true)
      Module.register_attribute(__MODULE__, :current_content_type, accumulate: false)
      Module.register_attribute(__MODULE__, :body_description, accumulate: false)
      Module.register_attribute(__MODULE__, :headers, accumulate: true)
      Module.register_attribute(__MODULE__, :examples, accumulate: true)

      # Used to collect schema definition metadata
      Module.register_attribute(__MODULE__, :fields, accumulate: true)
      Module.register_attribute(__MODULE__, :partials, accumulate: true)

      # Set defaults for non-accumulators
      @current_content_type nil
      @body_description nil
    end
  end

  ### Macro Helpers ###

  # Opens up a shared content body definition (i.e. request body or response)
  def def_content_body(type, name, do: block) do
    quote do
      unquote(block)

      def unquote(type)(:name), do: unquote(name)
      def unquote(type)(:desc), do: @body_description
      def unquote(type)(:headers), do: @headers |> Enum.reverse()
      def unquote(type)(:content_types), do: @content_types |> Enum.reverse()
    end
  end

  # Sets the description of a content body
  def set_desc(str) do
    quote do
      @body_description unquote(str)
    end
  end

  # Sets the headers for a response
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

  # Opens up a content body chunk for a specific content-type (e.g. "application/json")
  def def_content_type_shape(type, key, do: block) do
    quote do
      @content_types unquote(key)
      @current_content_type unquote(key)

      unquote(block)

      def unquote(type)({unquote(key), :examples}), do: @examples |> Enum.reverse()

      Module.delete_attribute(__MODULE__, :examples)
    end
  end

  # Sets an example for the current content-type
  def set_example(type, name, example_body) do
    quote do
      @examples unquote(name)

      def unquote(type)({@current_content_type, :examples, unquote(name)}),
        do: unquote(example_body)
    end
  end

  # Opens up a schema definition. This helper is used both to define shared
  # schema modules (Rolodex.Schema) and to define inline schemas via the macro
  # DSL within content bodies
  def set_schema(type, do: block) do
    quote do
      unquote(block)

      # @current_content_type will be `nil` when using this helper in Rolodex.Schema
      def unquote(type)({@current_content_type, :schema}) do
        fields = Map.new(@fields, fn {id, opts} -> {id, Field.new(opts)} end)
        partials = @partials |> Enum.reverse()

        Field.new(
          type: :object,
          properties: Rolodex.DSL.schema_fields_with_partials(fields, partials)
        )
      end

      Module.delete_attribute(__MODULE__, :fields)
      Module.delete_attribute(__MODULE__, :partials)
    end
  end

  # Sets the schema for the current content-type
  def set_schema(type, mods) when is_list(mods) do
    quote do
      def unquote(type)({@current_content_type, :schema}) do
        Field.new(type: :list, of: unquote(mods))
      end
    end
  end

  # Sets the schema for the current content-type
  def set_schema(type, mod) do
    quote do
      def unquote(type)({@current_content_type, :schema}) do
        Field.new(unquote(mod))
      end
    end
  end

  # Sets the schema for the current content-type
  def set_schema(type, collection_type, of: mods) do
    quote do
      def unquote(type)({@current_content_type, :schema}) do
        Field.new(type: unquote(collection_type), of: unquote(mods))
      end
    end
  end

  # Sets a field within a schema block or headers block
  def set_field(attr, identifier, list_items, _opts) when is_list(list_items) do
    quote do
      Module.put_attribute(
        __MODULE__,
        unquote(attr),
        {unquote(identifier), [type: :list, of: unquote(list_items)]}
      )
    end
  end

  # Sets a field within a schema block or headers block
  def set_field(attr, identifier, type, opts) do
    quote do
      Module.put_attribute(
        __MODULE__,
        unquote(attr),
        {unquote(identifier), [type: unquote(type)] ++ unquote(opts)}
      )
    end
  end

  # Sets a partial within a schema block
  def set_partial(mod) do
    quote do
      @partials Field.new(unquote(mod))
    end
  end

  ### Function Helpers ###

  # Check the given module against the given module type
  def is_module_of_type?(mod, type) when is_atom(mod) do
    try do
      mod.__info__(:functions) |> Keyword.has_key?(type)
    rescue
      _ -> false
    end
  end

  def is_module_of_type?(_), do: false

  # Serializes content body metadata
  def to_content_body_map(fun) do
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

  # Collects nested refs in a content body
  def get_refs_in_content_body(fun) do
    fun
    |> to_content_body_map()
    |> Map.take([:headers, :content])
    |> collect_refs(MapSet.new())
    |> Enum.to_list()
  end

  defp collect_refs(data, refs) do
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

  # Merges partials into schema fields
  def schema_fields_with_partials(fields, []), do: fields

  def schema_fields_with_partials(fields, partials),
    do: Enum.reduce(partials, fields, &merge_partial/2)

  defp merge_partial(%{type: :ref, ref: ref}, fields),
    do: ref |> Schema.to_map() |> merge_partial(fields)

  defp merge_partial(%{properties: props}, fields), do: Map.merge(fields, props)
end
