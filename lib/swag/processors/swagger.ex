defmodule Swag.Processors.Swagger do
  @behaviour Swag.Processor
  @open_api_version "3.0.0"

  @impl Swag.Processor
  def process(%Swag{} = data, _config) do
    %{
      data.path => %{
        data.verb => %{
          "description" => data.description,
          "responses" => data.responses
        }
      }
    }
    |> Jason.encode!()
  end

  @impl Swag.Processor
  def init(config) do
    """
    {\"info\":{
      \"description\":\"#{config.description}\",
      \"title\":\"#{config.title}\",
      \"version\":\"#{config.version}\"},
    \"openapi\":\"#{@open_api_version}\",
    \"paths\":[
    """
  end

  @impl Swag.Processor
  def finalize(_config) do
    """
    ]}
    """
  end
end
