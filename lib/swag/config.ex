defmodule Swag.Config do
  @enforce_keys [:processor, :writer, :version, :router, :title, :description, :version]

  defstruct [
    :router,
    :pipe_through_mapping,
    :writer,
    :version,
    :title,
    :description,
    :version,
    filter: :none,
    processor: Swag.Processors.Swagger,
  ]

  def new(map) do
    struct(__MODULE__, map)
  end
end
