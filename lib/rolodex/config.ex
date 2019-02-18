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
  - `writer` (default: `Rolodex.WriterConfig.t()`) - Destination
  for writing and a module implementing the `Rolodex.Writer` behaviour

  ## Example

    config :rolodex,
      title: "MyApp",
      description: "An example",
      version: "1.0.0",
      router: MyRouter,
      processor: Rolodex.Processors.Swagger,
      writer: [
        file_name: "my_docs.json",
        module: Rolodex.Writers.FileWriter
      ],
      pipelines: [
        api: [
          headers: %{"X-Request-Id" => :uuid}
        ]
      ]

  """

  alias Rolodex.{PipelineConfig, WriterConfig}

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
    :pipelines,
    :router,
    :title,
    :version,
    :writer,
    filters: :none,
    locale: "en",
    processor: Rolodex.Processors.Swagger
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
          writer: WriterConfig.t()
        }

  @type pipeline_configs :: %{
          optional(:atom) => Rolodex.PipelineConfig.t()
        }

  @spec new(list()) :: Rolodex.Config.t()
  def new(kwl \\ []) do
    opts =
      kwl
      |> Map.new()
      |> set_writer_config()
      |> set_pipelines_config()

    struct(__MODULE__, opts)
  end

  defp set_writer_config(opts), do: Map.put(opts, :writer, get_writer_config(opts))

  defp get_writer_config(%{writer: writer}), do: WriterConfig.new(writer)
  defp get_writer_config(_), do: WriterConfig.new()

  defp set_pipelines_config(opts), do: Map.put(opts, :pipelines, get_pipelines_config(opts))

  defp get_pipelines_config(%{pipelines: pipelines}) do
    Map.new(pipelines, fn {k, v} -> {k, PipelineConfig.new(v)} end)
  end

  defp get_pipelines_config(_), do: %{}
end

defmodule Rolodex.WriterConfig do
  @moduledoc """
  Defines writer config params.

  - `file_name` (default: `openapi.json`) - name of the docs output file, it will
  be written to the root directory of your project
  - `module` (default: `Rolodex.Writers.FileWriter`) - the writer behaviour to use
  """

  defstruct file_name: "openapi.json",
            module: Rolodex.Writers.FileWriter

  @type t :: %__MODULE__{
          file_name: binary(),
          module: module()
        }

  @spec new(list() | map()) :: t()
  def new(opts \\ []), do: struct(__MODULE__, opts)
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

  @spec new(list() | map()) :: t()
  def new(params \\ []) do
    opts = Map.new(params, fn {k, v} -> {k, Map.new(v)} end)
    struct(__MODULE__, opts)
  end
end
