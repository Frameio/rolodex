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

  * **`id`** (Default: `""`)

  Route identifier. Used as an optional unique identifier for the route.

      @doc [
        id: "foobar"
      ]

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

  * **`auth`** (Default: `%{}`)

  Define auth requirements for the route. Valid input is a single atom or a list
  of auth patterns. We only support logical OR auth definitions: if you provide
  a list of auth patterns, Rolodex will serialize this as any one of those auth
  patterns is required.

      @doc [
        # Simplest: auth pattern with no scope patterns
        auth: :MySimpleAuth,

        # One auth pattern with some scopes
        auth: [OAuth: ["user.read"]],

        # Multiple auth patterns
        auth: [
          :MySimpleAuth,
          OAuth: ["user.read"]
        ]
      ]

  * **`headers`** (Default: `%{}`)

  Request headers. Valid inputs: a module that has defined shared heads via
  `Rolodex.Headers`, or a map or keyword list, where each key is a header name
  and each value is a description of the value in the form of a an atom, a map,
  or a list.

  Each header value can also specify the following: `minimum` (default: `nil`),
  `maximum` (default: `nil`), default (default: `nil`), and required (default: `required`).

      @doc [
        # Shared headers
        headers: MySharedRequestHeaders

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

        # Multiple header values
        headers: [
          "X-Request-ID": :uuid,
          "Custom-Data": [
            id: :uuid,
            checksum: :string
          ]
        ]
      ]

  * **`path_params`** (Default: `%{}`)

  Parameters in the route path. Valid input is a map or keyword list, where each
  key is a path parameter name and each value is a description of the value in
  the form of an atom, a map, or a list.

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
  of an atom, a map, or a list.

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

        # Multiple query values
        query_params: [
          id: :uuid,
          some_object: [
            id: :uuid,
            checksum: :string
          ]
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

  ## Handling Multi-Path Actions

  Sometimes, a Phoenix controller action function will be used for multiple
  router paths. Sometimes, the documentation for each path will differ
  significantly. If you would like for each router path to pair with its own
  docs, you can use the `multi` flag.

      # Your router
      defmodule MyRouter do
        scope "/api" do
          get "/first", MyController, :index
          get "/:id/second", MyController, :index
        end
      end

      # Your controller
      defmodule MyController do
        @doc [
          # Flagged as an action with multiple docs
          multi: true,

          # All remaining top-level keys should be router paths
          "/api/first": [
            responses: %{200 => MyResponse}
          ],
          "/api/:id/second": [
            path_params: [
              id: [type: :integer, required: true]
            ],
            responses: ${200 => MyResponse}
          ]
        ]
        def index(conn, _), do: conn
      end
  """

  alias Phoenix.Router

  alias Rolodex.{
    Config,
    Headers,
    PipelineConfig,
    Field
  }

  import Rolodex.Utils, only: [to_struct: 2, ok: 1]

  defstruct [
    :path,
    :verb,
    id: "",
    auth: %{},
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
          id: binary(),
          auth: map(),
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
    with {:ok, desc, metadata} <- fetch_route_docs(phoenix_route),
         {:ok, route_data} <- parse_route_docs(metadata, desc, phoenix_route, config) do
      build_route(route_data, phoenix_route, config)
    else
      _ -> nil
    end
  end

  defp build_route(route_data, phoenix_route, config) do
    pipeline_config = fetch_pipeline_config(phoenix_route, config)

    phoenix_route
    |> Map.take(@phoenix_route_params)
    |> deep_merge(pipeline_config)
    |> deep_merge(route_data)
    |> to_struct(__MODULE__)
  end

  # Uses `Code.fetch_docs/1` to lookup `@doc` annotations for the controller action
  defp fetch_route_docs(phoenix_route) do
    case do_docs_fetch(phoenix_route) do
      {_, _, _, desc, metadata} -> {:ok, desc, metadata}
      _ -> {:error, :not_found}
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

  defp parse_route_docs(nil, _, _, _), do: {:error, :not_found}

  defp parse_route_docs(kwl, desc, route, config) when is_list(kwl) do
    kwl
    |> Map.new()
    |> parse_route_docs(desc, route, config)
  end

  defp parse_route_docs(
         %{multi: true} = metadata,
         desc,
         %Router.Route{path: path} = route,
         config
       ) do
    metadata
    |> get_doc_for_path(path)
    |> parse_route_docs(desc, route, config)
  end

  defp parse_route_docs(metadata, desc, _, config) do
    metadata
    |> parse_param_fields()
    |> Map.put(:desc, parse_description(desc, config))
    |> ok()
  end

  # When finding docs keyed by route path, the path key could be a string or atom.
  # So we want to handle both cases, safely (i.e. no `String.to_atom/1`)
  defp get_doc_for_path(metadata, path) do
    metadata
    |> Enum.find(fn
      {k, _} when is_atom(k) -> Atom.to_string(k) == path
      {k, _} -> k == path
    end)
    |> case do
      {_, doc} -> doc
      _ -> nil
    end
  end

  defp parse_param_fields(metadata) do
    metadata
    |> parse_body()
    |> parse_params()
    |> parse_auth()
  end

  defp parse_body(metadata) do
    case Map.get(metadata, :body) do
      nil -> metadata
      body -> %{metadata | body: Field.new(body)}
    end
  end

  defp parse_params(metadata) do
    [:headers, :path_params, :query_params, :responses]
    |> Enum.reduce(metadata, fn key, acc ->
      Map.update(acc, key, %{}, &parse_param/1)
    end)
  end

  defp parse_param(param) when is_atom(param) do
    case Headers.is_headers_module?(param) do
      true -> Headers.to_map(param)
      false -> Field.new(param)
    end
  end

  defp parse_param(param) do
    Map.new(param, fn {k, v} -> {k, Field.new(v)} end)
  end

  defp parse_auth(metadata) do
    auth =
      metadata
      |> Map.get(:auth, %{})
      |> do_parse_auth()
      |> Map.new()

    Map.put(metadata, :auth, auth)
  end

  defp do_parse_auth(auth, level \\ 0)
  defp do_parse_auth({key, value}, _), do: {key, value}
  defp do_parse_auth(auth, 0) when is_atom(auth), do: [{auth, []}]
  defp do_parse_auth(auth, _) when is_atom(auth), do: {auth, []}

  defp do_parse_auth(auth, level) when is_list(auth),
    do: Enum.map(auth, &do_parse_auth(&1, level + 1))

  defp do_parse_auth(auth, _), do: auth

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
