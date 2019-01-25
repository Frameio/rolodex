defmodule Rolodex.Config do
  alias Rolodex.PipeThroughMap

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
    :pipe_through_mapping,
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
          pipe_through_mapping: pipe_through_mapping | nil,
          processor: module(),
          router: module(),
          title: binary(),
          version: binary(),
          writer: keyword()
        }

  @type pipe_through_mapping :: %{
          optional(:atom) => PipeThroughMap.t()
        }

  def new(kwl \\ []) do
    struct(__MODULE__, kwl)
  end
end
