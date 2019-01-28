defmodule Rolodex.Route do
  @moduledoc """
  Logic to transform a `Phoenix.Router.Route` into metadata for a
  `Rolodex.Processor` to process. We use the `Rolodex.Config` data provided to
  resolve shared params for pipelines and locale-based descriptions.

  This module isn't intended to be invoked directly, but instead via the steps
  encapsulated in `Rolodex.generate_routes/1`.

  ## Example

  When you annotate your Phoenix Controller actions with `@doc` metadata, we pick
  out the parts meaningful to Rolodex.Writers

    ## Your controller
    defmodule MyController do
      @doc [
        headers: %{foo: :bar},
        body: %{foo: :bar},
        query_params: %{"foo" => "bar"},
        responses: %{200 => MyResponse},
        metadata: %{public: true},
        tags: ["foo", "bar"]
      ]
      @doc "My index action"
      def index(conn, _), do: conn
    end

    ## Will become
    %Rolodex.Route{
      description: "My index action",
      headers: %{foo: :bar},
      body: %{foo: :bar},
      query_params: %{"foo" => "bar"},
      responses: %{200 => MyResponse},
      metadata: %{public: true},
      tags: ["foo", "bar"],
      path: <from-phoenix>
      pipe_through: <from-phoenix>
      verb: <from-phoenix>
    }
  """

  alias Phoenix.Router
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

  @doc """
  Generates a new `Rolodex.Route` from a Phoenix Route struct and any
  `Rolodex.Config` data.
  """
  @spec new(Phoenix.Router.Route.t(), Rolodex.Config.t()) :: Rolodex.Route.t()
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

  @doc """
  Takes a Phoenix Route struct and uses `Code.fetch_docs/1` to lookup the
  docs for the route's controller action. We return only the description and doc
  metadata that are used to build the `Rolodex.Route.t()` result.

  ## Example

    defmodule MyController do
      @doc [
        headers: %{foo: :bar},
        metadata: %{foo: :bar}
      ]
      @doc "My index action"
      def index(conn, _), do: conn
    end

    iex> Rolodex.Route.fetch_route_docs(%Phoenix.Router.Route{plug: MyController, opts: :index})
    {
      %{"en" => "My index action"},
      %{headers: %{foo: :bar}, metadata: %{foo: :bar}}
    }
  """
  @spec fetch_route_docs(Phoenix.Router.Route.t()) :: {map() | atom() | binary(), map()}
  def fetch_route_docs(%Router.Route{plug: plug, opts: action}) do
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

  @doc """
  Builds shared `Rolodex.PipelineConfig` data for the given route. The config
  result will be empty if the route is not piped through any router pipelines or
  if there is no shared pipelines data in your `Rolodex.Config`.

  ## Example

    iex> router = %Phoenix.Router.Route{pipe_through: [:api]}
    iex> config = %Rolodex.Config{pipelines: %{api: %{headers: %{foo: :bar}}}}

    iex> Rolodex.Route.get_pipeline_config(router, config)
    %Rolodex.PipelineConfig{body: %{}, headers: %{foo: :bar}, query_params: %{}}
  """
  @spec get_pipeline_config(Phoenix.Router.Route.t(), Rolodex.Config.t()) ::
          Rolodex.PipelineConfig.t()
  def get_pipeline_config(phoenix_route, rolodex_config)

  def get_pipeline_config(%Router.Route{pipe_through: nil}, _), do: PipelineConfig.new()
  def get_pipeline_config(_, %Config{pipelines: nil}), do: PipelineConfig.new()

  def get_pipeline_config(%Router.Route{pipe_through: pipe_through}, %Config{pipelines: pipelines}) do
    Enum.reduce(pipe_through, PipelineConfig.new(), fn pt, acc ->
      pipeline_config =
        pipelines
        |> Map.get(pt, %{})
        |> PipelineConfig.new()

      deep_merge(acc, pipeline_config)
    end)
  end

  @doc """
  Takes function description metadata and returns a string. When the metadata is
  a map keyed by locale, we use the locale set in `Rolodex.Config` to determine
  which description string to return.
  """
  @spec parse_description(atom() | map() | binary(), Rolodex.Config.t()) :: binary()
  def parse_description(description, config)

  def parse_description(:none, _), do: ""

  def parse_description(description, %Config{locale: locale}) when is_map(description) do
    Map.get(description, locale, "")
  end

  def parse_description(description, _), do: description

  defp deep_merge(left, right), do: Map.merge(left, right, &deep_resolve/3)
  defp deep_resolve(_key, left = %{}, right = %{}), do: deep_merge(left, right)
  defp deep_resolve(_key, _left, right), do: right
end
