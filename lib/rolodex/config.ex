defmodule Rolodex.Config do
  @moduledoc """
  Configuration for Rolodex.

  You can define this config in your `config/<env>.exs` files, keyed by
  `:rolodex`, and it will be passed into `new/1` in `Mix.Tasks.GenDocs.run/1`.

  ## Options

  - `description` (required) - Description for your documentation output
  - `router` (required) - `Phoenix.Router` module to inspect
  - `title` (required) - Title for your documentation output
  - `version` (required) - Your documentation's version
  - `filters` (default: `:none`) - A list of maps or functions used to filter
  out routes from your documentation. Filters are matched against `Rolodex.Route`
  structs in `Rolodex.Route.matches_filter?/2`.
  - `locale` (default: `"en"`) - Locale key to use when processing descriptions
  - `pipelines` (default: `%{}`) - Map of pipeline configs. Used to set default
  parameter values for all routes in a pipeline. See `Rolodex.PipelineConfig`.
  - `processor` (default: `Rolodex.Processors.Swagger`) - Module implementing
  the `Rolodex.Processor` behaviour
  - `writer` (default: `%{file_path: "", writer: Rolodex.Writers.FileWriter`) - Destination
  for writing and a module implementing the `Rolodex.Writer` behaviour

  ## Example

    config :rolodex,
      title: "MyApp",
      description: "An example",
      version: "1.0.0",
      router: MyRouter,
      processor: Rolodex.Processors.Swagger,
      writer: %{
        file_path: "/",
        module: Rolodex.Writers.FileWriter
      },
      pipelines: %{
        api: %{
          headers: %{"X-Request-Id" => :uuid}
        }
      }

  """

  @enforce_keys [
    :description,
    :locale,
    :processor,
    :router,
    :title,
    :version,
    :writer
  ]

  defstruct [
    :description,
    :router,
    :title,
    :version,
    filters: :none,
    locale: "en",
    pipelines: %{},
    processor: Rolodex.Processors.Swagger,
    writer: %{
      file_path: "",
      module: Rolodex.Writers.FileWriter
    }
  ]

  @type t :: %__MODULE__{
          description: binary(),
          filters: [map() | (Rolodex.Route.t() -> boolean())] | :none,
          locale: binary(),
          pipelines: pipeline_configs() | nil,
          processor: module(),
          router: module(),
          title: binary(),
          version: binary(),
          writer: map()
        }

  @type pipeline_configs :: %{
          optional(:atom) => Rolodex.PipelineConfig.t()
        }

  @spec new(list()) :: Rolodex.Config.t()
  def new(kwl \\ []) do
    struct(__MODULE__, kwl)
  end
end

defmodule Rolodex.PipelineConfig do
  @moduledoc """
  Defines shared params to be applied to every route within a Phoenix pipeline.

  ## Options

  - `body` (default: `%{}`)
  - `headers` (default: `%{}`)
  - `path_params` (default: `%{}`)
  - `query_params` (default: `%{}`)

  ## Example

    %Rolodex.PipelineConfig{
      body: %{id: :uuid, name: :string}
      headers: %{"X-Request-Id" => :uuid},
      query_params: %{account_id: :uuid}
    }
  """

  defstruct body: %{},
            headers: %{},
            path_params: %{},
            query_params: %{}

  @type t :: %__MODULE__{
          body: map(),
          headers: map(),
          path_params: map(),
          query_params: map()
        }

  @spec new(map()) :: Rolodex.PipelineConfig.t()
  def new(params \\ %{}) do
    struct(__MODULE__, params)
  end
end
