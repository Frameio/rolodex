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
        # TODO(billyc): this leaves open the posibility that a user can write an
        # invalid response structure. maybe we should enforce _always_ using response
        # schemas in doc annotations?
        {status_code, response}

      _ ->
        # TODO(billyc): swagger requires us to key responses underneath content
        # type keys. we should probably add this as a configuration level.
        response_blob = %{
          content: %{
            "application/json" => %{
              "$ref" => ref_path(response)
            }
          }
        }

        {status_code, response_blob}
    end
  end

  defp process_response(response, _), do: response

  @impl Rolodex.Processor
  def process_schemas(schemas) do
    schemas
    |> Flow.from_enumerable()
    |> Flow.map(fn {mod, schema} ->
      {mod.__object__(:name), process_schema(schema)}
    end)
    |> Map.new()
  end

  defp process_schema(%{type: :object, ref: ref}) do
    %{"$ref" => ref_path(ref)}
  end

  defp process_schema(%{type: :object, properties: props}) do
    %{
      type: :object,
      properties: props |> Map.new(fn {k, v} -> {k, process_schema(v)} end)
    }
  end

  defp process_schema(%{type: :array, items: item}) when is_map(item) do
    %{
      type: :array,
      items: process_schema(item)
    }
  end

  defp process_schema(%{type: :array, items: items}) when is_list(items) do
    %{
      type: :array,
      items: %{
        oneOf: items |> Enum.map(&process_schema/1)
      }
    }
  end

  defp process_schema(%{type: :uuid}), do: %{type: :string, format: :uuid}
  defp process_schema(%{type: type}), do: %{type: type}

  defp finalize(headers, routes, schemas) do
    headers
    |> Map.merge(%{"paths" => routes, "components" => %{"schemas" => schemas}})
    |> Jason.encode!()
  end

  defp ref_path(mod), do: "#/components/schemas/#{mod.__object__(:name)}"
end
