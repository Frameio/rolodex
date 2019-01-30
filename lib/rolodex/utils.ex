defmodule Rolodex.Utils do
  @doc """
  Determines if an arbitrary `item` is a module that has defined a Rolodex.Object
  """
  @spec can_generate_schema?(any()) :: boolean()
  def can_generate_schema?(item)

  # TODO(billyc): I don't love this approach, but am struggling to develop a
  # better approach. I tried using a protocol that would be implemented as part
  # of the `Rolodex.Object.object/3` macro. But, that doesn't really seem to serve
  # our needs b/c protocls need structs to work:
  #
  # `OurProtocol.to_schema_map(MyObject)` <- will fallback to Any b/c we didn't pass in %MyObject{}
  def can_generate_schema?(item) when is_atom(item) do
    try do
      # Alternatively, we could use `:erlang.function_exported/3`, but I found
      # that returns false negatives in test often b/c the module passed in isn't
      # loaded properly.
      item.__info__(:functions)
      |> Keyword.has_key?(:to_schema_map)
    rescue
      # Any error means that `item` isn't a module and so we can just say `false`
      _ -> false
    end
  end

  def can_generate_schema?(_), do: false
end
