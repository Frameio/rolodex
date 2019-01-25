defmodule Rolodex.Processors.Swagger do
  @behaviour Rolodex.Processor
  @open_api_version "3.0.0"

  @impl Rolodex.Processor
  def process(config, routes, schemas) do
    headers = process_headers(config)
    processed_routes = process_routes(routes, schemas)
    processed_schemas = process_schemas(schemas)

    finalize(headers, processed_routes, processed_schemas)
  end

  @impl Rolodex.Processor
  def process_headers(config) do
    %{
      "openapi" => @open_api_version,
      "info" => %{
        "title" => config.title,
        "description" => config.description,
        "version" => config.version
      }
    }
  end

  @impl Rolodex.Processor
  def process_routes(routes, schemas) do
    routes
    |> Flow.from_enumerable()
    |> Flow.map(&process_route(&1, schemas))
    |> Enum.to_list()
  end

  @impl Rolodex.Processor
  def process_schemas(schemas) do
    schemas
    |> Map.new(fn {mod, schema} -> {mod.__object__(:name), schema} end)
  end

  defp process_route(route, schemas) do
    %{
      route.path => %{
        route.verb => %{
          "description" => route.description,
          "responses" => process_responses(route.responses, schemas)
        }
      }
    }
  end

  defp process_responses(responses, schemas) do
    responses
    |> Map.new(&process_response(&1, schemas))
  end

  defp process_response({status_code, response}, schemas) when is_atom(response) do
    case Map.get(schemas, response) do
      nil ->
        {status_code, response}

      _ ->
        {status_code, "#/components/#{response.__object__(:type)}s/#{response.__object__(:name)}"}
    end
  end

  defp process_response(response, _), do: response

  defp finalize(headers, routes, schemas) do
    headers
    |> Map.merge(%{"paths" => routes, "components" => %{"schemas" => schemas}})
    |> Jason.encode!()
  end
end
