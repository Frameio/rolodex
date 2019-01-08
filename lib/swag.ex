defmodule Swag do
  @moduledoc """
  Documentation for Swag.
  """

  alias Swag.PipeThroughMap

  defstruct [
    :body,
    :description,
    :path,
    :pipe_through,
    :query_params,
    :responses,
    :tags,
    :verb,
    headers: %{},
    metadata: %{},
  ]

  @type t :: %__MODULE__{
    body: binary(),
    description: binary(),
    headers: %{},
    metadata: %{},
    path: binary(),
    pipe_through: [atom()],
    query_params: %{},
    responses: %{},
    tags: [binary()],
    verb: atom(),
  }

  def generate_documentation(config) do
    %{processor: processor, writer: writer} = config
    writer = Keyword.fetch!(writer, :module)

    {:ok, device} = writer.init(config)
    writer.write(device, processor.init(config))

    paths =
      config.router.__routes__
      |> Flow.from_enumerable()
      |> Flow.map(&generate_swag_struct(&1, config))
      |> Flow.reject(fn item ->
        case config.filter do
          :none -> false
          filter -> item == filter
        end
      end)
      |> Flow.map(&processor.process(&1, config))
      |> Enum.join(",")

    writer.write(device, paths)
    writer.write(device, processor.finalize(config))
    writer.close(device)
  end

  def generate_swag_struct(route, config) do
    %{path: path, pipe_through: pipe_through, plug: plug, verb: verb, opts: action} = route

    Code.fetch_docs(plug)
    |> find_action(action)
    |> new(config, path: path, pipe_through: pipe_through, plug: plug, verb: verb)
  end

  def new(doc, config, kwl \\ []) do
    {_, _, _, description, documentation_metadata} =
      case doc do
        nil -> {:any, :any, :any, "", %{}}
        doc -> doc
      end

    optional = Map.new(kwl)

    description = case description do
      :none -> ""
      description when is_map(description) -> Map.get(description, config.locale)
      description -> description
    end

    %{headers: pipe_headers} =
      optional
      |> Map.get(:pipe_through)
      |> pipe_through_mapping(config)

    headers = Map.get(documentation_metadata, :headers, %{})
    headers = deep_merge(pipe_headers, headers)

    data =
      optional
      |> deep_merge(documentation_metadata)
      |> deep_merge(%{headers: headers})
      |> Map.put(:description, description)
      |> Map.put(:metadata, Map.get(documentation_metadata, :metadata, %{}))

    struct(%__MODULE__{}, data)
  end

  def pipe_through_mapping(nil, _), do: PipeThroughMap.new()
  def pipe_through_mapping(_, %{pipe_through_mapping: nil}), do: PipeThroughMap.new()
  def pipe_through_mapping(pipe_through, config) when is_list pipe_through do
    Enum.reduce(pipe_through, PipeThroughMap.new(), fn pt, acc ->
      case pipe_through_mapping(pt, config) do
        nil -> acc
        mapping ->
          Map.merge(acc, mapping, fn
            k, v1, v2 when k in [:headers, :query_params, :body] -> Map.merge(v1, v2)
            _, _, v2 -> v2
          end)
      end
    end)
  end
  def pipe_through_mapping(pipe_through, config) do
    Map.get(config.pipe_through_mapping, pipe_through, nil)
    |> PipeThroughMap.new()
  end

  defp deep_merge(left, right), do: Map.merge(left, right, &deep_resolve/3)
  defp deep_resolve(_key, left = %{}, right = %{}), do: deep_merge(left, right)
  defp deep_resolve(_key, _left, right), do: right

  defp find_action(docs, action) do
    {_, _, _, _, _, _, function_documentation} = docs

    Enum.find(function_documentation, fn {{:function, ac, _arity}, _, _, _, _} ->
      ac == action
    end)
  end
end
