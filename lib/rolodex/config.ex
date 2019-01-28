defmodule Rolodex.Config do
  @moduledoc """
  Configuration for Rolodex. You can define this config in your
  `config/<env>.exs` files, keyed by `:rolodex`, and we will pull it out in
  `Mix.Tasks.GenDocs.run/1`.

  ## Options

  - `title` (required) - Title for your documentation output
  - `description` (required) - Description for your documentation output
  - `version` (required) - Your documentation's version
  - `router` (required) - Phoenix Router module to inspect
  - `processor` (default: `Rolodex.Processors.Swagger)   -
  - `writer` (default: `%{file_path: "", writer: Rolodex.Writers.FileWriter`) - Map
  - `locale` (default: `"en"`) - Locale key to use when processing controller
  action descriptions
  - `filter` (default: `:none`) - TODO
  - `pipelines` (default: `%{}`) - Map of `Rolodex.PipelineConfig`s

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
    :title,
    :description,
    :version,
    :router,
    :processor,
    :writer,
    :locale
  ]

  defstruct [
    :title,
    :description,
    :version,
    :router,
    processor: Rolodex.Processors.Swagger,
    writer: %{
      file_path: "",
      module: Rolodex.Writers.FileWriter
    },
    locale: "en",
    filter: :none,
    pipelines: %{}
  ]

  @type t :: %__MODULE__{
          title: binary(),
          description: binary(),
          version: binary(),
          router: module(),
          processor: module(),
          writer: map(),
          locale: binary(),
          filter: keyword() | :none,
          pipelines: pipeline_configs() | nil
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
            query_params: %{}

  @type t :: %__MODULE__{
          body: map(),
          headers: map(),
          query_params: map()
        }

  @spec new(map()) :: Rolodex.PipelineConfig.t()
  def new(params \\ %{}) do
    struct(__MODULE__, params)
  end
end
