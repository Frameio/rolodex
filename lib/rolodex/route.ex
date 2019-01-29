defmodule Rolodex.Route do
  @moduledoc """
  Logic to process and represent a single route path in your API.
  """

  alias Rolodex.{Config, PipelineConfig}

  defstruct [
    :description,
    :path,
    :verb,
    body: %{},
    headers: %{},
    query_params: %{},
    metadata: %{},
    responses: %{},
    pipe_through: %{},
    tags: []
  ]

  @type t :: %__MODULE__{
          body: %{},
          description: binary(),
          headers: %{},
          metadata: %{},
          path: binary(),
          pipe_through: [atom()],
          query_params: %{},
          responses: %{},
          tags: [binary()],
          verb: atom()
        }

  def new(phoenix_route, config) do
    # Get docs defined with the route controller action
    {action_description, action_metadata} = fetch_route_docs(phoenix_route)

    # Get shared params for any route pipelines
    pipeline_config = get_pipeline_config(phoenix_route, config)

    # Merge it all together against base params from the Phoenix.Router.Route
    data =
      phoenix_route
      |> Map.take([:path, :pipe_through, :verb])
      |> deep_merge(Map.from_struct(pipeline_config))
      |> deep_merge(action_metadata)
      |> Map.put(:description, parse_description(action_description, config))

    struct(__MODULE__, data)
  end

  def fetch_route_docs(%{plug: plug, opts: action}) do
    {_, _, _, desc, metadata} =
      Code.fetch_docs(plug)
      |> Tuple.to_list()
      |> Enum.at(-1)
      |> Enum.find(fn
        {{:function, ^action, _arity}, _, _, _, _} -> true
        _ -> false
      end)

    {desc, metadata}
  end

  def get_pipeline_config(%{pipe_through: nil}, _), do: PipelineConfig.new()
  def get_pipeline_config(_, %Config{pipelines: nil}), do: PipelineConfig.new()

  def get_pipeline_config(%{pipe_through: pipe_through}, %Config{pipelines: pipelines}) do
    Enum.reduce(pipe_through, PipelineConfig.new(), fn pt, acc ->
      pipeline_config =
        pipelines
        |> Map.get(pt, %{})
        |> PipelineConfig.new()

      deep_merge(acc, pipeline_config)
    end)
  end

  def parse_description(:none, _), do: ""

  def parse_description(description, %Config{locale: locale}) when is_map(description) do
    Map.get(description, locale)
  end

  def parse_description(description, _), do: description

  defp deep_merge(left, right), do: Map.merge(left, right, &deep_resolve/3)
  defp deep_resolve(_key, left = %{}, right = %{}), do: deep_merge(left, right)
  defp deep_resolve(_key, _left, right), do: right
end
