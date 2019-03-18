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
  - `file_name` (default: "api.json") - The name of the output file with the processed
  documentation
  - `filters` (default: `:none`) - A list of maps or functions used to filter
  out routes from your documentation. Filters are matched against `Rolodex.Route`
  structs in `Rolodex.Route.matches_filter?/2`.
  - `locale` (default: `"en"`) - Locale key to use when processing descriptions
  - `pipelines` (default: `%{}`) - Map of pipeline configs. Used to set default
  parameter values for all routes in a pipeline. See `Rolodex.PipelineConfig`.
  - `processor` (default: `Rolodex.Processors.Swagger`) - Module implementing
  the `Rolodex.Processor` behaviour
  - `server_urls` (default: []) - List of base url(s) for your API paths
  - `writer` (default: `Rolodex.Writers.FileWriter`) - Module implementing the
  `Rolodex.Writer` behaviour to be used to write out the docs

  ## Full Example

      defmodule MyRolodexConfig do
        use Rolodex.Config

        def spec() do
          [
            title: "My API",
            description: "My API's description",
            version: "1.0.0",
            default_content_type: "application/json+api",
            file_name: "api.json",
            filters: :none,
            locale: "en",
            processor: MyProcessor,
            server_urls: ["https://myapp.io"],
            router: MyRouter
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

  alias Rolodex.{PipelineConfig, Utils}

  @enforce_keys [
    :description,
    :file_name,
    :locale,
    :processor,
    :router,
    :title,
    :version,
    :writer
  ]

  defstruct [
    :description,
    :pipelines,
    :router,
    :title,
    :version,
    default_content_type: "application/json",
    file_name: "api.json",
    filters: :none,
    locale: "en",
    processor: Rolodex.Processors.Swagger,
    auth: %{},
    server_urls: [],
    writer: Rolodex.Writers.FileWriter
  ]

  @type t :: %__MODULE__{
          default_content_type: binary(),
          description: binary(),
          file_name: binary(),
          filters: [map() | (Rolodex.Route.t() -> boolean())] | :none,
          locale: binary(),
          pipelines: pipeline_configs() | nil,
          processor: module(),
          router: module(),
          auth: map(),
          server_urls: [binary()],
          title: binary(),
          version: binary(),
          writer: module()
        }

  @type pipeline_configs :: %{
          optional(:atom) => PipelineConfig.t()
        }

  @callback spec() :: keyword() | map()
  @callback pipelines_spec() :: keyword() | map()

  defmacro __using__(_) do
    quote do
      @behaviour Rolodex.Config

      def spec(), do: %{}
      def pipelines_spec(), do: %{}
      def auth_spec(), do: %{}

      defoverridable spec: 0, pipelines_spec: 0, auth_spec: 0
    end
  end

  @spec new(module()) :: t()
  def new(module) do
    module.spec()
    |> Map.new()
    |> set_pipelines_config(module)
    |> set_auth_config(module)
    |> Utils.to_struct(__MODULE__)
  end

  defp set_pipelines_config(opts, module) do
    pipelines =
      module.pipelines_spec()
      |> Map.new(fn {k, v} -> {k, PipelineConfig.new(v)} end)

    Map.put(opts, :pipelines, pipelines)
  end

  def set_auth_config(opts, module),
    do: Map.put(opts, :auth, module.auth_spec() |> Utils.to_map_deep())
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

  alias Rolodex.Utils

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
    |> Map.new(fn {k, v} -> {k, Utils.to_map_deep(v)} end)
    |> Utils.to_struct(__MODULE__)
  end
end
