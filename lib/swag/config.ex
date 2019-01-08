defmodule Swag.Config do
  @enforce_keys [:processor, :writer, :version, :router, :title, :description, :version]

  defstruct [
    :router,
    :pipe_through_mapping,
    :version,
    :title,
    :description,
    :version,
    filter: :none,
    writer: [
      config: [
        :file_path
      ],
      module: Swag.Writers.FileWriter,
    ],
    processor: Swag.Processors.Swagger,
  ]

  def new(kwl \\ []) do
    struct(__MODULE__, kwl)
  end
end
