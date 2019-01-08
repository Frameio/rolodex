defmodule Swag do
  defstruct [
    :body,
    :description,
    :headers,
    :metadata,
    :path,
    :pipe_through,
    :query_params,
    :responses,
    :verb,
    :tags
  ]

  @moduledoc """
  Documentation for Swag.
  """

  def generate_documentation(config) do
    %{processor: processor, writer: writer} = config
    writer = Keyword.fetch!(writer, :module)

    {:ok, device} = writer.init(config)
    writer.write(device, processor.init(config))

    paths =
      config.router.__routes__
      |> Flow.from_enumerable()
      |> Flow.map(&generate_swag_struct(&1))
      |> Flow.reject(fn item ->
        case config.filter do
          :none -> false
          filter -> item == filter
        end
      end)
      |> Flow.map(&processor.process(&1, config))
      |> Enum.join(",")

    writer.write(device, paths)
    writer.write(device, processor.finish(config))
    writer.close(device)
  end

  def generate_swag_struct(route) do
    %{path: path, pipe_through: pipe_through, plug: plug, verb: verb, opts: action} = route

    Code.fetch_docs(plug)
    |> find_action(action)
    |> new(path: path, pipe_through: pipe_through, plug: plug, verb: verb)
  end

  def find_action(docs, action) do
    {_, _, _, _, _, _, function_documentation} = docs

    Enum.find(function_documentation, fn {{:function, ac, _arity}, _, _, _, _} ->
      ac == action
    end)
  end

  def new(doc, kwl \\ []) do
    {_, _, _, description, metadata} =
      case doc do
        nil -> {:any, :any, :any, "", %{}}
        doc -> doc
      end

    data = Map.new(kwl)

    %{headers: pipe_headers} = pipe_through_mapping(data.pipe_through)

    headers = Map.get(metadata, :headers, %{})
    headers = Map.merge(pipe_headers, headers)

    data =
      data
      |> Map.merge(metadata)
      |> Map.put(:headers, headers)
      |> Map.put(:description, description)
      |> Map.put(:metadata, Map.get(metadata, :metadata, %{}))

    struct(%__MODULE__{}, data)
  end

  def pipe_through_mapping(_any), do: %{headers: %{}, query_params: %{}, body: %{}}

  def to_doc(data, processor) do
    processor.process(data)
  end
end
