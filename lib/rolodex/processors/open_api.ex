defmodule Rolodex.Processors.OpenAPI do
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

  alias Rolodex.{Config, Field, Headers, Route}

  import Rolodex.Utils, only: [camelize_map: 1]

  @impl Rolodex.Processor
  def process(config, routes, serialized_refs) do
    config
    |> process_headers()
    |> Map.put(:paths, process_routes(routes, config))
    |> Map.put(:components, process_refs(serialized_refs, config))
    |> Jason.encode!(pretty: true)
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
  def process_routes(routes, config) do
    routes
    |> Enum.group_by(&path_with_params/1)
    |> Map.new(fn {path, routes} ->
      {path, process_routes_for_path(routes, config)}
    end)
  end

  # Transform Phoenix-style path params to Swagger-style: /foo/:bar -> /foo/{bar}
  defp path_with_params(%Route{path: path}) do
    ~r/\/:([^\/]+)/
    |> Regex.replace(path, fn _, path_param -> "/{#{path_param}}" end)
  end

  defp process_routes_for_path(routes, config) do
    Map.new(routes, fn %Route{verb: verb} = route ->
      {verb, process_route(route, config)}
    end)
  end

  defp process_route(route, config) do
    result = %{
      # Swagger prefers `summary` for short, one-line descriptions of a route,
      # whereas `description` is meant for multi-line markdown explainers.
      #
      # TODO(bceskavich): we could support both?
      operationId: route.id,
      summary: route.desc,
      tags: route.tags,
      parameters: process_params(route),
      security: process_auth(route),
      responses: process_responses(route, config)
    }

    case process_body(route, config) do
      body when map_size(body) == 0 -> result
      body -> Map.put(result, :requestBody, body)
    end
  end

  defp process_params(%Route{headers: headers, path_params: path, query_params: query}) do
    [header: headers, path: path, query: query]
    |> Enum.flat_map(fn {location, params} ->
      Enum.map(params, &process_param(&1, location))
    end)
  end

  defp process_param({name, param}, location) do
    %{
      in: location,
      name: name,
      schema: process_schema_field(param)
    }
    |> set_param_required(param)
    |> set_param_description()
  end

  defp set_param_required(param, %{required: true}), do: Map.put(param, :required, true)
  defp set_param_required(param, _), do: param

  defp process_auth(%Route{auth: auth}), do: Enum.map(auth, &Map.new([&1]))

  defp process_body(%Route{body: body}, _) when map_size(body) == 0, do: body
  defp process_body(%Route{body: %{type: :ref} = body}, _), do: process_schema_field(body)

  defp process_body(%Route{body: body}, %Config{default_content_type: content_type}) do
    %{
      content: %{
        content_type => %{schema: process_schema_field(body)}
      }
    }
  end

  defp process_responses(%Route{responses: responses}, _) when map_size(responses) == 0,
    do: responses

  defp process_responses(%Route{responses: responses}, %Config{default_content_type: content_type}) do
    responses
    |> Map.new(fn
      {status_code, :ok} ->
        {status_code, %{description: "OK"}}

      {status_code, %{type: :ref} = response} ->
        {status_code, process_schema_field(response)}

      {status_code, response} ->
        resp = %{
          content: %{
            content_type => %{schema: process_schema_field(response)}
          }
        }

        {status_code, resp}
    end)
  end

  @impl Rolodex.Processor
  def process_refs(
        %{
          request_bodies: request_bodies,
          responses: responses,
          schemas: schemas
        },
        %Config{auth: auth}
      ) do
    %{
      requestBodies: process_content_body_refs(request_bodies, :__request_body__),
      responses: process_content_body_refs(responses, :__response__),
      schemas: process_schema_refs(schemas),
      securitySchemes: camelize_map(auth)
    }
  end

  defp process_content_body_refs(refs, ref_type) do
    Map.new(refs, fn {mod, ref} ->
      name = apply(mod, ref_type, [:name])
      content = process_content_body_ref(ref)
      {name, content}
    end)
  end

  defp process_content_body_ref(%{desc: desc, content: content} = rest) do
    %{
      description: desc,
      content:
        content
        |> Map.new(fn {content_type, content_val} ->
          {content_type, process_content_body_ref_data(content_val)}
        end)
    }
    |> process_content_body_headers(rest)
  end

  defp process_content_body_ref_data(%{schema: schema, examples: examples}) do
    %{
      schema: process_schema_field(schema),
      examples: process_content_body_examples(examples)
    }
  end

  defp process_content_body_examples(examples),
    do: Map.new(examples, fn {name, example} -> {name, %{value: example}} end)

  defp process_content_body_headers(content, %{headers: []}), do: content

  defp process_content_body_headers(content, %{headers: headers}),
    do: Map.put(content, :headers, Enum.reduce(headers, %{}, &serialize_headers_group/2))

  # OpenAPI 3 does not support using `$ref` syntax for reusable header components,
  # so we need to serialize them out in full each time.
  defp serialize_headers_group(%{type: :ref, ref: ref}, serialized) do
    headers =
      ref
      |> Headers.to_map()
      |> process_header_fields()

    Map.merge(serialized, headers)
  end

  defp serialize_headers_group(headers, serialized),
    do: Map.merge(serialized, process_header_fields(headers))

  defp process_header_fields(fields) do
    Map.new(fields, fn {header, value} -> {header, process_header_field(value)} end)
  end

  defp process_header_field(value) do
    %{schema: process_schema_field(value)}
    |> set_param_description()
  end

  defp process_schema_refs(schemas) do
    Map.new(schemas, fn {mod, schema} ->
      {mod.__schema__(:name), process_schema_field(schema)}
    end)
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

  # When serializing parameters, descriptions should be placed in the top-level
  # parameters map, not the nested schema definition
  defp set_param_description(%{schema: %{description: description} = schema} = param) do
    param
    |> Map.put(:description, description)
    |> Map.put(:schema, Map.delete(schema, :description))
  end

  defp set_param_description(param), do: param

  defp ref_path(mod) do
    case Field.get_ref_type(mod) do
      :request_body -> "#/components/requestBodies/#{mod.__request_body__(:name)}"
      :response -> "#/components/responses/#{mod.__response__(:name)}"
      :schema -> "#/components/schemas/#{mod.__schema__(:name)}"
    end
  end
end
