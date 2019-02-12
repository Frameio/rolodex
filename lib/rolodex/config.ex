defmodule Rolodex.Config do
  @moduledoc """
  Configuration for Rolodex.

  You can define this config in your `config/<env>.exs` files, keyed by
  `:rolodex`, and it will be passed into `new/1` in `Mix.Tasks.GenDocs.run/1`.

  ## Options

  - `description` (required) - Description for your documentation output
  - `router` (required) - Phoenix Router module to inspect
  - `title` (required) - Title for your documentation output
  - `version` (required) - Your documentation's version
  - `filter` (default: `:none`) - TODO
  - `locale` (default: `"en"`) - Locale key to use when processing controller
  - `pipelines` (default: `%{}`) - Map of `Rolodex.PipelineConfig`s
  - `processor` (default: `Rolodex.Processors.Swagger`) - Module implementing
  the Rolodex.Processor behaviour
  - `writer` (default: `%{file_path: "", writer: Rolodex.Writers.FileWriter`) - Map
  action descriptions

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
          headers: %{auth: true}
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
    filter: :none,
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
          filter: keyword() | :none,
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
  - `query_params` (default: `%{}`)

  ## Example

    %Rolodex.PipelineConfig{
      body: %{foo: :bar},
      headers: %{bar: :baz},
      query_params: %{foo: :bar}
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