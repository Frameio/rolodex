defmodule Rolodex.Route do
  @moduledoc """
  Collects metadata associated with an API route.

  `new/2` takes a `Phoenix.Router.Route`, finds the controller action
  function associated with the route, and collects metadata set in the `@doc`
  annotations for the function.

  ### Fields

  * **`desc`** (Default: `""`)

  Set via an `@doc` comment

      @doc [
        # Other annotations here
      ]
      @doc "My route description"
      def route(_, _), do: nil

  * **`body`** *(Default: `%{}`)

  Request body parameters. Valid inputs: `Rolodex.RequestBody`, or a map or
  keyword list describing a parameter schema. When providing a plain map or
  keyword list, the request body schema will be set under the default content
  type value set in `Rolodex.Config`.

      @doc [
        # A shared request body defined via `Rolodex.RequestBody`
        body: SomeRequestBody,

        # Request body is a JSON object with two parameters: `id` and `name`
        body: %{id: :uuid, name: :string},
        body: [id: :uuid, name: :string],

        # Same as above, but here the top-level data structure `type` is specified
        # so that we can add `desc` metadata to it
        body: %{
          type: :object,
          desc: "The request body",
          properties: %{id: :uuid}
        },
        body: [
          type: :object,
          desc: "The request body",
          properties: [id: :uuid]
        ],

        # Request body is a JSON array of strings
        body: [:string],

        # Same as above, but here the top-level data structure `type` is specified
        body: %{type: :list, of: [:string]},
        body: [type: :list, of: [:string]],

        # All together
        body: [
          id: :uuid,
          name: [type: :string, desc: "The name"],
          ages: [:number]
        ]
      ]

  * **`headers`** (Default: `%{}`)

  Request headers. Valid input is a map or keyword list, where each key is a
  header name and each value is a description of the value in the form of a
  `Rolodex.Schema`, an atom, a map, or a list.

  Each header value can also specify the following: `minimum` (default: `nil`),
  `maximum` (default: `nil`), default (default: `nil`), and required (default: `required`).

      @doc [
        # Simplest header description: a name with a concrete type
        headers: %{"X-Request-ID" => :uuid},
        headers: ["X-Request-ID": :uuid],

        # Specifying metadata for the header value
        headers: %{
          "X-Request-ID" => %{
            type: :integer,
            required: true,
            minimum: 0,
            maximum: 10,
            default: 0
          }
        },
        headers: [
          "X-Request-ID": [
            type: :integer,
            required: true,
            minimum: 0,
            maximum: 10,
            default: 0
          ]
        ],

        # Multiple header values. Maybe some of the have nested attributes too
        headers: [
          "X-Request-ID": :uuid,
          "Custom-Data": [
            id: :uuid,
            checksum: :string
          ],
          "Header-Via-Schema": MyHeaderSchema
        ]
      ]

  * **`path_params`** (Default: `%{}`)

  Parameters in the route path. Valid input is a map or keyword list, where each
  key is a path parameter name and each value is a description of the value in
  the form of a `Rolodex.Schema`, an atom, a map, or a list.

  Each parameter value can also specify the following: `minimum` (default:
  `nil`), `maximum` (default: `nil`), default (default: `nil`), and required
  (default: `required`).

      @doc [
        # Simplest path parameter description: a name with a concrete type
        path_params: %{id: :uuid},
        path_params: [id: :uuid],

        # Specifying metadata for the path value
        path_params: %{
          id: %{
            type: :integer,
            required: true,
            minimum: 0,
            maximum: 10,
            default: 0
          }
        },
        path_params: [
          id: [
            type: :integer,
            required: true,
            minimum: 0,
            maximum: 10,
            default: 0
          ]
        ]
      ]

  * **`query_params`** (Default: `%{}`)

  Query parameters. Valid input is a map or keyword list, where each key is a
  query parameter name and each value is a description of the value in the form
  of a `Rolodex.Schema`, an atom, a map, or a list.

  Each query value can also specify the following: `minimum` (default: `nil`),
  `maximum` (default: `nil`), default (default: `nil`), and required (default:
  `required`).

      @doc [
        # Simplest query parameter description: a name with a concrete type
        query_params: %{id: :uuid},
        query_params: [id: :uuid],

        # Specifying metadata for the parameter value
        query_params: %{
          id: %{
            type: :integer,
            required: true,
            minimum: 0,
            maximum: 10,
            default: 0
          }
        },
        query_params: [
          id: [
            type: :integer,
            required: true,
            minimum: 0,
            maximum: 10,
            default: 0
          ]
        ],

        # Multiple query values. Maybe some of the have nested attributes too
        query_params: [
          id: :uuid,
          some_object: [
            id: :uuid,
            checksum: :string
          ],
          via_schema: QueryParamSchema
        ]
      ]

  * **`responses`** (Default: `%{}`)

  Response(s) for the route action. Valid input is a map or keyword list, where
  each key is a response code and each value is a description of the response in
  the form of a `Rolodex.Response`, an atom, a map, or a list.

      @doc [
        responses: %{
          # A response defined via a reusable schema
          200 => MyResponse,

          # Use `:ok` for simple success responses
          200 => :ok,

          # Response is a JSON object with two parameters: `id` and `name`
          200 => %{id: :uuid, name: :string},
          200 => [id: :uuid, name: :string],

          # Same as above, but here the top-level data structure `type` is specified
          # so that we can add `desc` metadata to it
          200 => %{
            type: :object,
            desc: "The response body",
            properties: %{id: :uuid}
          },
          200 => [
            type: :object,
            desc: "The response body",
            properties: [id: :uuid]
          ],

          # Response is a JSON array of a schema
          200 => [MyResponse],

          # Same as above, but here the top-level data structure `type` is specified
          200 => %{type: :list, of: [MyResponse]},
          200 => [type: :list, of: [MyResponse]],

          # Response is one of multiple possible results
          200 => %{type: :one_of, of: [MyResponse, OtherResponse]},
          200 => [type: :one_of, of: [MyResponse, OtherResponse]],
        }
      ]

  * **`metadata`** (Default: `%{}`)

  Any metadata for the route. Valid input is a map or keyword list.

  * **`tags`** (Default: `[]`)

  Route tags. Valid input is a list of strings.

  ## Handling Route Pipelines

  In your `Rolodex.Config`, you can specify shared route parameters for your
  Phoenix pipelines. For each route, if it is part of a pipeline, `new/2` will
  merge in shared pipeline config data into the route metadata

      # Your Phoenix router
      defmodule MyRouter do
        pipeline :api do
          plug MyPlug
        end

        scope "/api" do
          pipe_through [:api]

          get "/test", MyController, :index
        end
      end

      # Your controller
      defmodule MyController do
        @doc [
          headers: ["X-Request-ID": uuid],
          responses: %{200 => :ok}
        ]
        @doc "My index action"
        def index(conn, _), do: conn
      end

      # Your config
      config = %Rolodex.Config{
        pipelines: %{
          api: %{
            headers: %{"Shared-Header" => :string}
          }
        }
      }

      # Parsed route
      %Rolodex.Route{
        headers: %{
          "X-Request-ID" => %{type: :uuid},
          "Shared-Header" => %{type: :string}
        },
        responses: %{200 => :ok}
      }
  """

  alias Phoenix.Router

  alias Rolodex.{
    Config,
    PipelineConfig,
    Field
  }

  defstruct [
    :path,
    :verb,
    body: %{},
    desc: "",
    headers: %{},
    metadata: %{},
    path_params: %{},
    pipe_through: [],
    query_params: %{},
    responses: %{},
    tags: []
  ]

  @phoenix_route_params [:path, :pipe_through, :verb]

  @type t :: %__MODULE__{
          body: map(),
          desc: binary(),
          headers: %{},
          metadata: %{},
          path: binary(),
          path_params: %{},
          pipe_through: [atom()],
          query_params: %{},
          responses: %{},
          tags: [binary()],
          verb: atom()
        }

  @doc """
  Checks to see if the given route matches any filter(s) stored in `Rolodex.Config`.
  """
  @spec matches_filter?(t(), Rolodex.Config.t()) :: boolean()
  def matches_filter?(route, config)

  def matches_filter?(route, %Config{filters: filters}) when is_list(filters) do
    Enum.any?(filters, fn
      filter_opts when is_map(filter_opts) ->
        keys = Map.keys(filter_opts)
        Map.take(route, keys) == filter_opts

      filter_fun when is_function(filter_fun) ->
        filter_fun.(route)

      _ ->
        false
    end)
  end

  def matches_filter?(_, _), do: false

  @doc """
  Looks up a `Phoenix.Router.Route` controller action function, parses any
  doc annotations, and returns as a struct.
  """
  @spec new(Phoenix.Router.Route.t(), Rolodex.Config.t()) :: t() | nil
  def new(phoenix_route, config) do
    with action_doc_data when is_map(action_doc_data) <- fetch_route_docs(phoenix_route, config) do
      pipeline_config = fetch_pipeline_config(phoenix_route, config)

      phoenix_route
      |> Map.take(@phoenix_route_params)
      |> deep_merge(pipeline_config)
      |> deep_merge(action_doc_data)
      |> to_struct()
    else
      _ -> nil
    end
  end

  defp to_struct(data), do: struct(__MODULE__, data)

  # Uses `Code.fetch_docs/1` to lookup `@doc` annotations for the controller action
  defp fetch_route_docs(phoenix_route, config) do
    case do_docs_fetch(phoenix_route) do
      {_, _, _, desc, metadata} ->
        metadata
        |> parse_param_fields()
        |> Map.put(:desc, parse_description(desc, config))

      _ ->
        nil
    end
  end

  defp do_docs_fetch(%Router.Route{plug: plug, opts: action}) do
    plug
    |> Code.fetch_docs()
    |> Tuple.to_list()
    |> Enum.at(-1)
    |> Enum.find(fn
      {{:function, ^action, _arity}, _, _, _, _} -> true
      _ -> false
    end)
  end

  defp parse_param_fields(metadata) do
    metadata =
      case Map.get(metadata, :body, nil) do
        nil ->
          metadata

        body ->
          %{metadata | body: Field.new(body)}
      end

    [:headers, :path_params, :query_params, :responses]
    |> Enum.reduce(metadata, fn key, acc ->
      fields =
        acc
        |> Map.get(key, %{})
        |> Map.new(fn {k, v} -> {k, Field.new(v)} end)

      Map.put(acc, key, fields)
    end)
  end

  defp parse_description(:none, _), do: ""

  defp parse_description(description, %Config{locale: locale}) when is_map(description) do
    Map.get(description, locale, "")
  end

  defp parse_description(description, _), do: description

  # Builds shared `Rolodex.PipelineConfig` data for the given route. The config
  # result will be empty if the route is not piped through any router pipelines or
  # if there is no shared pipelines data in `Rolodex.Config`.
  defp fetch_pipeline_config(%Router.Route{pipe_through: nil}, _), do: %{}

  defp fetch_pipeline_config(_, %Config{pipelines: pipelines}) when map_size(pipelines) == 0,
    do: %{}

  defp fetch_pipeline_config(%Router.Route{pipe_through: pipe_through}, %Config{
         pipelines: pipelines
       }) do
    Enum.reduce(pipe_through, %{}, fn pt, acc ->
      pipeline_config =
        pipelines
        |> Map.get(pt, %PipelineConfig{})
        |> Map.from_struct()
        |> parse_param_fields()

      deep_merge(acc, pipeline_config)
    end)
  end

  defp deep_merge(left, right), do: Map.merge(left, right, &deep_resolve/3)
  defp deep_resolve(_key, left = %{}, right = %{}), do: deep_merge(left, right)
  defp deep_resolve(_key, _left, right), do: right
end
