defmodule Swag.Processors.Swagger do
  @behaviour Swag.Processor
  @open_api_version "3.0.0"

  @impl Swag.Processor
  def process(%Swag{} = data, schemas, _config) do
    %{
      data.path => %{
        data.verb => %{
          "description" => data.description,
          "responses" => process_responses(data.responses, schemas)
        }
      }
    }
    |> Jason.encode!()
  end

  defp process_responses(responses, schemas) do
    responses
    |> Map.new(&process_response(&1, schemas))
  end

  defp process_response({status_code, response}, schemas) when is_atom(response) do
    case Map.get(schemas, response) do
      nil -> {status_code, response}
      _ -> {status_code, "#/components/#{response.__object__(:type)}s/#{response.__object__(:name)}"}
    end
  end

  defp process_response(response, _), do: response

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
