defmodule Rolodex.Config do
  @moduledoc """
  A behaviour for defining Rolodex config and functions to parse config.

  To define your config for Rolodex, `use` Rolodex.Config in a module and
  override the default behaviour functions. Then, tell Rolodex the name of your
  config module in your project's configuration files.

      # Your config definition
      defmodule MyRolodexConfig do
        use Rolodex.Config

        def spec() do
          [
            title: "My API",
            description: "My API's description",
            version: "1.0.0"
          ]
        end
      end

      # In `config.exs`
      config :rolodex, module: MyRolodexConfig

  ## Usage

  Your Rolodex config module exports three functions, which each return an empty
  list by default:

  - `spec/0` - Basic configuration for your Rolodex setup
  - `render_groups_spec/0` - Definitions for render targets for your API docs. A
  render group is combination of: (optional) route filters, a processor, a writer,
  and options for the writer. You can specify more than one render group to create
  multiple docs outputs for your API. By default, one render group will be defined
  using the default values in `Rolodex.RenderGroupConfig`.
  - `auth_spec/0` - Definitions for shared auth patterns to be used in routes.
  Auth definitions should follow the OpenAPI pattern, but keys can use snake_case
  and will be converted to camelCase for the OpenAPI target.
  - `pipelines_config/0` - Sets any shared defaults for your Phoenix Router
  pipelines. See `Rolodex.PipelineConfig` for details about valid options and defaults

  For `spec/0`, the following are valid options:

  - `description` (required) - Description for your documentation output
  - `router` (required) - `Phoenix.Router` module to inspect
  - `title` (required) - Title for your documentation output
  - `version` (required) - Your documentation's version
  - `default_content_type` (default: "application/json") - Default content type
  used for request body and response schemas
  - `locale` (default: `"en"`) - Locale key to use when processing descriptions
  - `pipelines` (default: `%{}`) - Map of pipeline configs. Used to set default
  parameter values for all routes in a pipeline. See `Rolodex.PipelineConfig`.
  - `render_groups` (default: `%Rolodex.RenderGroupConfig{}`) - List of render
  groups.
  - `server_urls` (default: []) - List of base url(s) for your API paths

  ## Full Example

      defmodule MyRolodexConfig do
        use Rolodex.Config

        def spec() do
          [
            title: "My API",
            description: "My API's description",
            version: "1.0.0",
            default_content_type: "application/json+api",
            locale: "en",
            server_urls: ["https://myapp.io"],
            router: MyRouter
          ]
        end

        def render_groups_spec() do
          [
            [writer_opts: [file_name: "api-public.json"]],
            [writer_opts: [file_name: "api-private.json"]]
          ]
        end

        def auth_spec() do
          [
            BearerAuth: [
              type: "http",
              scheme: "bearer"
            ],
            OAuth: [
              type: "oauth2",
              flows: [
                authorization_code: [
                  authorization_url: "https://example.io/oauth2/authorize",
                  token_url: "https://example.io/oauth2/token",
                  scopes: [
                    "user.read",
                    "account.read",
                    "account.write"
                  ]
                ]
              ]
            ]
          ]
        end

        def pipelines_spec() do
          [
            api: [
              headers: ["X-Request-ID": :uuid],
              query_params: [includes: :string]
            ]
          ]
        end
      end
  """

  alias Rolodex.{PipelineConfig, RenderGroupConfig}

  import Rolodex.Utils, only: [to_struct: 2, to_map_deep: 1]

  @enforce_keys [
    :description,
    :locale,
    :render_groups,
    :router,
    :title,
    :version
  ]

  defstruct [
    :description,
    :pipelines,
    :render_groups,
    :router,
    :title,
    :version,
    default_content_type: "application/json",
    locale: "en",
    auth: %{},
    server_urls: []
  ]

  @type t :: %__MODULE__{
          default_content_type: binary(),
          description: binary(),
          locale: binary(),
          pipelines: pipeline_configs() | nil,
          render_groups: [RenderGroupConfig.t()],
          router: module(),
          auth: map(),
          server_urls: [binary()],
          title: binary(),
          version: binary()
        }

  @type pipeline_configs :: %{
          optional(:atom) => PipelineConfig.t()
        }

  @callback spec() :: keyword() | map()
  @callback pipelines_spec() :: keyword() | map()
  @callback auth_spec() :: keyword() | map()
  @callback render_groups_spec() :: list()

  defmacro __using__(_) do
    quote do
      @behaviour Rolodex.Config

      def spec(), do: %{}
      def pipelines_spec(), do: %{}
      def auth_spec(), do: %{}
      def render_groups_spec(), do: [[]]

      defoverridable spec: 0,
                     pipelines_spec: 0,
                     auth_spec: 0,
                     render_groups_spec: 0
    end
  end

  @spec new(module()) :: t()
  def new(module) do
    module.spec()
    |> Map.new()
    |> set_pipelines_config(module)
    |> set_auth_config(module)
    |> set_render_groups_config(module)
    |> to_struct(__MODULE__)
  end

  defp set_pipelines_config(opts, module) do
    pipelines =
      module.pipelines_spec()
      |> Map.new(fn {k, v} -> {k, PipelineConfig.new(v)} end)

    Map.put(opts, :pipelines, pipelines)
  end

  defp set_auth_config(opts, module),
    do: Map.put(opts, :auth, module.auth_spec() |> to_map_deep())

  defp set_render_groups_config(opts, module) do
    groups = module.render_groups_spec() |> Enum.map(&RenderGroupConfig.new/1)
    Map.put(opts, :render_groups, groups)
  end
end

defmodule Rolodex.RenderGroupConfig do
  @moduledoc """
  Configuration for a render group, a serialization target for your docs. You can
  specify one or more render groups via `Rolodex.Config` to render docs output(s)
  for your API.

  ## Options

  - `filters` (default: `:none`) - A list of maps or functions used to filter
  out routes from your documentation. Filters are invoked in
  `Rolodex.Route.matches_filter?/2`. If the match returns true, the route will be
  filtered out of the docs result for this render group.
  - `processor` (default: `Rolodex.Processors.Swagger`) - Module implementing
  the `Rolodex.Processor` behaviour
  - `writer` (default: `Rolodex.Writers.FileWriter`) - Module implementing the
  `Rolodex.Writer` behaviour to be used to write out the docs
  - `writer_opts` (default: `[file_name: "api.json"]`) - Options keyword list
  passed into the writer behaviour.
  """

  defstruct filters: :none,
            processor: Rolodex.Processors.Swagger,
            writer: Rolodex.Writers.FileWriter,
            writer_opts: [file_name: "api.json"]

  @type t :: %__MODULE__{
          filters: [map() | (Rolodex.Route.t() -> boolean())] | :none,
          processor: module(),
          writer: module(),
          writer_opts: keyword()
        }

  @spec new(list() | map()) :: t()
  def new(params \\ []), do: struct(__MODULE__, params)
end

defmodule Rolodex.PipelineConfig do
  @moduledoc """
  Defines shared params to be applied to every route within a Phoenix pipeline.

  ## Options

  - `body` (default: `%{}`)
  - `headers` (default: `%{}`)
  - `path_params` (default: `%{}`)
  - `query_params` (default: `%{}`)
  - `responses` (default: `%{}`)

  ## Example

      %Rolodex.PipelineConfig{
        body: %{id: :uuid, name: :string}
        headers: %{"X-Request-Id" => :uuid},
        query_params: %{account_id: :uuid},
        responses: %{401 => SharedUnauthorizedResponse}
      }
  """

  import Rolodex.Utils, only: [to_struct: 2, to_map_deep: 1]

  defstruct auth: [],
            body: %{},
            headers: %{},
            path_params: %{},
            query_params: %{},
            responses: %{}

  @type t :: %__MODULE__{
          auth: list() | map(),
          body: map(),
          headers: map(),
          path_params: map(),
          query_params: map(),
          responses: map()
        }

  @spec new(list() | map()) :: t()
  def new(params \\ []) do
    params
    |> Map.new(fn {k, v} -> {k, to_map_deep(v)} end)
    |> to_struct(__MODULE__)
  end
end
