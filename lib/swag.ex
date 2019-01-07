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
    :tags,
  ]

  @moduledoc """
  Documentation for Swag.
  """

  def generate_documentation(router, config) do
    %{processor: processor, writer: writer} = config

    {:ok, device} = writer.init(config)
    writer.write(device, processor.init(config))

    config.router.__routes__
    |> Flow.from_enumerable()
    |> Flow.map(&generate_route_documentation(&1, config))
    |> Flow.reject(fn item ->
      case config.filter do
        :none -> false
        filter -> item == filter
      end
    end)
    |> Flow.map(&processor.process(&1, config))
    |> Flow.each(&writer.write(device, &1))
    |> Flow.run()

    writer.write(device, processor.finish(config))
    writer.close(device)
  end

  def generate_route_documentation(route, config) do
    %{path: path, pipe_through: pipe_through, plug: plug, verb: verb, opts: action} = route

    Code.fetch_docs(plug)
    |> find_action(action)
    |> build_struct([path: path, pipe_through: pipe_through, plug: plug, verb: verb], config)
  end

  def find_action(docs, action) do
    {_, _, _, _, _, _, function_documentation} = docs

    Enum.find(function_documentation, fn {{:function, ac, _arity}, _, _, _, _} ->
      ac == action
    end)
  end

  def build_struct(doc, kwl, config) do
    {_, _, _, description, metadata} = doc

    data = Map.new(kwl)

    auth_headers = pipe_through_mapping(data.pipe_through)

    headers = Keyword.merge(metadata.headers, auth_headers)

    data =
      data
      |> Map.merge(metadata)
      |> Map.put(:headers, headers)
      |> Map.put(:description, description)
      |> Map.put(:metadata, Map.new(metadata.metadata))

    struct(%__MODULE__{}, data)
  end

  def pipe_through_mapping(any), do: %{headers: %{}, query_params: %{}, body: %{}}

  def to_doc(data, processor) do
    processor.process(data)
  end
end
