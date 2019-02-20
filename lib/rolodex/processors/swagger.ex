defmodule Rolodex.Processors.Swagger do
  @behaviour Rolodex.Processor
  @open_api_version "3.0.0"

  @schema_metadata_keys [
    :default,
    :enum,
    :format,
    :maximum,
    :minimum,
    :type
  ]

  alias Rolodex.{Config, Route}

  @impl Rolodex.Processor
  def process(config, routes, schemas) do
    headers = process_headers(config)
    processed_routes = process_routes(routes)
    processed_schemas = process_schemas(schemas)

    headers
    |> Map.merge(%{
      paths: processed_routes,
      components: %{
        schemas: processed_schemas
      }
    })
    |> Jason.encode!()
  end

  @impl Rolodex.Processor
  def process_headers(config) do
    %{
      openapi: @open_api_version,
      servers: process_server_urls(config),
      info: %{
        title: config.title,
        description: config.description,
        version: config.version
      }
    }
  end

  defp process_server_urls(%Config{server_urls: urls}) do
    for url <- urls, do: %{url: url}
  end

  @impl Rolodex.Processor
  def process_routes(routes) do
    routes
    |> Flow.from_enumerable()
    |> Flow.group_by(&path_with_params/1)
    |> Flow.map(fn {path, routes} ->
      {path, process_routes_for_path(routes)}
    end)
    |> Map.new()
  end

  # Transform Phoenix-style path params to Swagger-style: /foo/:bar -> /foo/{bar}
  defp path_with_params(%Route{path: path}) do
    ~r/\/:([^\/]+)/
    |> Regex.replace(path, fn _, path_param -> "/{#{path_param}}" end)
  end

  defp process_routes_for_path(routes) do
    Map.new(routes, fn %Route{verb: verb} = route ->
      {verb, process_route(route)}
    end)
  end

  defp process_route(route) do
    %{
      # Swagger prefers `summary` for short, one-line descriptions of a route,
      # whereas `description` is meant for multi-line markdown explainers.
      #
      # TODO(billyc): we could support both?
      summary: route.desc,
      parameters: process_params(route),
      requestBody: process_body(route),
      responses: process_responses(route)
    }
  end

  defp process_params(%Route{headers: headers, path_params: path, query_params: query}) do
    [{:header, headers}, {:path, path}, {:query, query}]
    |> Enum.flat_map(fn {location, params} ->
      Enum.map(params, &process_param(&1, location))
    end)
  end

  defp process_param({name, param}, location) do
    result = %{
      in: location,
      name: name,
      schema: process_schema_field(param)
    }

    case Map.get(param, :required, false) do
      true -> Map.put(result, :required, true)
      false -> result
    end
  end

  defp process_body(%Route{body: body}) when map_size(body) == 0, do: body

  defp process_body(%Route{body: body}) do
    %{
      content: %{
        # TODO(billyc): content type shouldn't be hard-code; should be configurable
        "application/json" => %{
          schema: process_schema_field(body)
        }
      }
    }
  end

  defp process_responses(%Route{responses: responses}) when map_size(responses) == 0,
    do: responses

  defp process_responses(%Route{responses: responses}) do
    responses
    |> Map.new(fn
      {status_code, :ok} ->
        {status_code, %{description: "OK"}}

      {status_code, response} ->
        response_data = %{
          content: %{
            # TODO(billyc): content type shouldn't be hard-code; should be configurable
            "application/json" => %{
              schema: process_schema_field(response)
            }
          }
        }

        {status_code, response_data}
    end)
  end

  @impl Rolodex.Processor
  def process_schemas(schemas) do
    schemas
    |> Flow.from_enumerable()
    |> Flow.map(fn {mod, schema} ->
      {mod.__schema__(:name), process_schema_field(schema)}
    end)
    |> Map.new()
  end

  defp process_schema_field(%{type: :ref, ref: ref}) when ref != nil do
    %{"$ref" => ref_path(ref)}
  end

  defp process_schema_field(%{type: :object, properties: props} = object_field) do
    object = %{
      type: :object,
      properties: props |> Map.new(fn {k, v} -> {k, process_schema_field(v)} end)
    }

    props
    |> collect_required_object_props()
    |> set_required_object_props(object)
    |> put_description(object_field)
  end

  defp process_schema_field(%{type: :list, of: items} = list_field) when length(items) == 1 do
    %{
      type: :array,
      items: items |> Enum.at(0) |> process_schema_field()
    }
    |> put_description(list_field)
  end

  defp process_schema_field(%{type: :list, of: items} = list_field) do
    %{
      type: :array,
      items: %{
        oneOf: items |> Enum.map(&process_schema_field/1)
      }
    }
    |> put_description(list_field)
  end

  defp process_schema_field(%{type: :one_of, of: items}) do
    %{
      oneOf: items |> Enum.map(&process_schema_field/1)
    }
  end

  defp process_schema_field(%{type: :uuid} = field) do
    field
    |> Map.merge(%{type: :string, format: :uuid})
    |> process_schema_field()
  end

  defp process_schema_field(field) do
    field
    |> Map.take(@schema_metadata_keys)
    |> put_description(field)
  end

  ## Helpers ##

  defp collect_required_object_props(props), do: Enum.reduce(props, [], &do_props_collect/2)

  defp do_props_collect({k, %{required: true}}, acc), do: [k | acc]
  defp do_props_collect(_, acc), do: acc

  defp set_required_object_props([], object), do: object
  defp set_required_object_props(required, object), do: Map.put(object, :required, required)

  defp put_description(field, %{desc: desc}) when is_binary(desc) and desc != "" do
    Map.put(field, :description, desc)
  end

  defp put_description(field, _), do: field

  defp ref_path(mod), do: "#/components/schemas/#{mod.__schema__(:name)}"
end
