defmodule Swag.Processors.Swagger do
  @behaviour Swag.Processor
  @open_api_version "3.0.0"

  @impl Swag.Processor
  def process(%Swag{} = data) do
    %{
      data.path => %{
        data.verb => %{
          "description" => data.description,
          "responses" => data.responses,
        },
      }
    } |> Jason.encode!
  end

  @imple Swag.Processor
  def init(config) do
    """
    {\"info\":{
      \"description\":\"#{config.description}\",
      \"title\":\"#{config.title}\",
      \"version\":\"#{config.version}\"},
    \"openapi\":\"#{@open_api_version}\"
    \"paths\":[
    """
  end

  @imple Swag.Processor
  def finish(_config) do
    """
    ]}
    """
  end
end
