defmodule Rolodex.Utils do
  @moduledoc false

  @doc """
  Pipeline friendly dynamic struct creator
  """
  def to_struct(data, module), do: struct(module, data)

  @doc """
  Recursively convert a keyword list into a map
  """
  def to_map_deep(data, level \\ 0)
  def to_map_deep([], 0), do: %{}

  def to_map_deep(list, level) when is_list(list) do
    case Keyword.keyword?(list) do
      true -> Map.new(list, fn {key, val} -> {key, to_map_deep(val, level + 1)} end)
      false -> list
    end
  end

  def to_map_deep(data, _), do: data

  @doc """
  Recursively convert all keys in a map from snake_case to camelCase
  """
  def camelize_map(data) when not is_map(data), do: data

  def camelize_map(data) do
    Map.new(data, fn {key, value} -> {camelize(key), camelize_map(value)} end)
  end

  defp camelize(key) when is_atom(key), do: key |> Atom.to_string() |> camelize()

  defp camelize(key) do
    case Macro.camelize(key) do
      ^key -> key
      camelized -> uncapitalize(camelized)
    end
  end

  defp uncapitalize(<<char, rest::binary>>), do: String.downcase(<<char>>) <> rest

  @doc """
  Similar to Ruby's `with_indifferent_access`, this function performs an indifferent
  key lookup on a map or keyword list. Indifference means that the keys :foo and
  "foo" are considered identical. We only convert from atom -> string to avoid
  the unsafe `String.to_atom/1` function.
  """
  @spec indifferent_find(map() | keyword(), atom() | binary()) :: any()
  def indifferent_find(data, key) when is_atom(key),
    do: indifferent_find(data, Atom.to_string(key))

  def indifferent_find(data, key) do
    data
    |> Enum.find(fn
      {k, _} when is_atom(k) -> Atom.to_string(k) == key
      {k, _} -> k == key
    end)
    |> case do
      {_, result} -> result
      _ -> nil
    end
  end

  @doc """
  Grabs the description and metadata map associated with the given function via
  `@doc` annotations.
  """
  @spec fetch_doc_annotation(module(), atom()) :: {:ok, binary(), map()} | {:error, :not_found}
  def fetch_doc_annotation(controller, action) do
    controller
    |> Code.fetch_docs()
    |> Tuple.to_list()
    |> Enum.at(-1)
    |> Enum.find(fn
      {{:function, ^action, _arity}, _, _, _, _} -> true
      _ -> false
    end)
    |> case do
      {_, _, _, desc, metadata} -> {:ok, desc, metadata}
      _ -> {:error, :not_found}
    end
  end
end
