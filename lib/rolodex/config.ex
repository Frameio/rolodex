defmodule Rolodex.Config do
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
    filter: :none,
    locale: "en",
    processor: Rolodex.Processors.Swagger,
    writer: [
      config: [
        :file_path
      ],
      module: Rolodex.Writers.FileWriter
    ]
  ]

  @type t :: %__MODULE__{
          description: binary(),
          filter: keyword() | nil,
          locale: binary(),
          pipelines: pipeline_configs() | nil,
          processor: module(),
          router: module(),
          title: binary(),
          version: binary(),
          writer: keyword()
        }

  @type pipeline_configs :: %{
          optional(:atom) => Rolodex.PipelineConfig.t()
        }

  def new(kwl \\ []) do
    struct(__MODULE__, kwl)
  end
end

defmodule Rolodex.PipelineConfig do
  defstruct body: %{},
            headers: %{},
            query_params: %{}

  @type t :: %__MODULE__{
          body: map,
          headers: map,
          query_params: map
        }

  def new(params \\ %{}) do
    struct(__MODULE__, params)
  end
end
