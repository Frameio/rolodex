defmodule Rolodex.Utils do
  def to_struct(data, module), do: struct(module, data)

  def to_map_deep(data, level \\ 0)
  def to_map_deep([], 0), do: %{}

  def to_map_deep(list, level) when is_list(list) do
    case Keyword.keyword?(list) do
      true -> Map.new(list, fn {key, val} -> {key, to_map_deep(val, level + 1)} end)
      false -> list
    end
  end

  def to_map_deep(data, _), do: data

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
end
