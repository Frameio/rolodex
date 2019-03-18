defmodule Rolodex do
  @moduledoc """
  Rolodex generates documentation for your Phoenix API.

  Rolodex inspects a Phoenix Router and transforms the `@doc` annotations on your
  controller actions into documentation in the format of your choosing.

  `Rolodex.run/1` encapsulates the full documentation generation process. When
  invoked, it will:

  1. Traverse your Phoenix Router
  2. Collect documentation data for the API endpoints exposed by your router
  3. Serialize the data into a format of your choosing (e.g. Swagger JSON)
  4. Write the serialized data out to a destination of your choosing.

  Rolodex can be configured in the `config/` files for your Phoenix project. See
  `Rolodex.Config` for more details on configuration options.

  ## Features and resources

  - **Reusable schemas** - See `Rolodex.Schema` for details on how define reusable
  parameter schemas. See `Rolodex.RequestBody` for details on how to use schemas
  in your API request body definitions. See `Rolodex.Response` for details on
  how to use schemas in your API response definitions.
  - **Structured annotations** - See `Rolodex.Route` for details on how to format
  annotations on your API route action functions for the Rolodex parser to handle
  - **Generic serialization** - The `Rolodex.Processor` behaviour encapsulates
  the basic steps needed to serialize API metadata into documentation. Rolodex
  ships with a valid Swagger JSON processor (see: `Rolodex.Processors.Swagger`)
  - **Generic writing** - The `Rolodex.Writer` behaviour encapsulates the basic
  steps needed to write out formatted docs. Rolodex ships with a file writer (
  see: `Rolodex.Writers.FileWriter`)

  ## High level example

      # Your Phoenix router
      defmodule MyRouter do
        pipeline :api do
          plug MyPlug
        end

        scope "/api" do
          pipe_through [:api]

          get "/test", MyController, :index
        end
      end

      # Your controller
      defmodule MyController do
        @doc [
          headers: ["X-Request-ID": uuid],
          query_params: [include: :string],
          path_params: [user_id: :uuid],
          body: MyRequestBody,
          responses: %{200 => MyResponse},
          metadata: [public: true],
          tags: ["foo", "bar"]
        ]
        @doc "My index action"
        def index(conn, _), do: conn
      end

      # Your request body
      defmodule MyRequestBody do
        use Rolodex.RequestBody

        request_body "MyRequestBody" do
          desc "A request body"

          content "application/json" do
            schema MySchema
            example :request, %{id: "123", name: "Ada Lovelace"}
          end
        end
      end

      # Your response
      defmodule MyResponse do
        use Rolodex.Response

        response "MyResponse" do
          desc "A response"

          content "application/json" do
            schema MySchema
            example :response, %{id: "123", name: "Ada Lovelace"}
          end
        end
      end

      # Your schema
      defmodule MySchema do
        use Rolodex.Schema

        schema "MySchema", desc: "A schema" do
          field :id, :uuid
          field :name, :string, desc: "The name"
        end
      end

      # In mix.exs
      config :rolodex,
        title: "MyApp",
        description: "An example",
        version: "1.0.0",
        router: MyRouter,
        pipelines: [
          api: [
            headers: ["Include-Meta": :boolean]
          ]
        ]

      # Then...
      Application.get_all_env(:rolodex)
      |> Rolodex.Config.new()
      |> Rolodex.run()

      # The JSON written out to file should look like
      %{
        "openapi" => "3.0.0",
        "info" => %{
          "title" => "MyApp",
          "description" => "An example",
          "version" => "1.0.0"
        },
        "paths" => %{
          "/api/test" => %{
            "get" => %{
              "metadata" => %{"public" => true},
              "parameters" => [
                %{
                  "in" => "header",
                  "name" => "X-Request-ID",
                  "schema" => %{
                    "type" => "string",
                    "format" => "uuid"
                  }
                },
                %{
                  "in" => "path",
                  "name" => "user_id",
                  "schema" => %{
                    "type" => "string",
                    "format" => "uuid"
                  }
                },
                %{
                  "in" => "query",
                  "name" => "include",
                  "schema" => %{
                    "type" => "string"
                  }
                }
              ],
              "responses" => %{
                "200" => %{
                  "$ref" => "#/components/responses/MyResponse"
                }
              },
              "requestBody" => %{
                "type" => "object",
                "properties" => %{
                  "id" => %{"type" => "string", "format" => "uuid"}
                }
              },
              "tags" => ["foo", "bar"]
            }
          }
        },
        "components" => %{
          "requestBodies" => %{
            "MyRequestBody" => %{
              "description" => "A request body",
              "content" => %{
                "application/json" => %{
                  "schema" => %{
                    "$ref" => "#/components/schemas/MySchema"
                  },
                  "examples" => %{
                    "request" => %{"id" => "123", "name" => "Ada Lovelace"}
                  }
                }
              }
            }
          },
          "responses" => %{
            "MyResponse" => %{
              "description" => "A response",
              "content" => %{
                "application/json" => %{
                  "schema" => %{
                    "$ref" => "#/components/schemas/MySchema"
                  },
                  "examples" => %{
                    "response" => %{"id" => "123", "name" => "Ada Lovelace"}
                  }
                }
              }
            }
          },
          "schemas" => %{
            "MySchema" => %{
              "type" => "object",
              "description" => "A schema",
              "properties" => %{
                "id" => %{"type" => "string", "format" => "uuid"},
                "name" => %{"type" => "string", "description" => "The name"}
              }
            }
          }
        }
      }
  """

  alias Rolodex.{
    Config,
    Field,
    RequestBody,
    Response,
    Route,
    Schema
  }

  @route_fields_with_refs [:body, :headers, :path_params, :query_params, :responses]

  @doc """
  Runs Rolodex and writes out documentation to the specified destination
  """
  @spec run(Rolodex.Config.t()) :: :ok | {:error, any()}
  def run(config) do
    generate_documentation(config)
    |> write(config)
  end

  defp write(processed, %Config{writer: writer} = config) do
    writer = Map.get(writer, :module)

    with {:ok, device} <- writer.init(config),
         :ok <- writer.write(device, processed),
         :ok <- writer.close(device) do
      :ok
    else
      err ->
        IO.puts("Failed to write docs with error:")
        IO.inspect(err)
    end
  end

  @doc """
  Generates a list of route docs and a map of response schemas. Passes both into
  the configured processor to generate the documentation JSON to be written to
  file.
  """
  @spec generate_documentation(Rolodex.Config.t()) :: String.t()
  def generate_documentation(%Config{processor: processor} = config) do
    routes = generate_routes(config)
    refs = generate_refs(routes)
    processor.process(config, routes, refs)
  end

  @doc """
  Inspects the Phoenix Router provided in your `Rolodex.Config`. Iterates
  through the list of routes to generate a `Rolodex.Route` for each. It will
  filter out any route(s) that match the filter(s) you provide in your config.
  """
  @spec generate_routes(Rolodex.Config.t()) :: [Rolodex.Route.t()]
  def generate_routes(%Config{router: router} = config) do
    router.__routes__()
    |> Flow.from_enumerable()
    |> Flow.map(&Route.new(&1, config))
    |> Flow.reject(&(&1 == nil || Route.matches_filter?(&1, config)))
    |> Enum.to_list()
  end

  @doc """
  Inspects the request and response parameter data for each `Rolodex.Route`.
  From these routes, it collects a unique list of `Rolodex.RequestBody`,
  `Rolodex.Response`, and `Rolodex.Schema` references. The serialized refs will
  be passed along to a `Rolodex.Processor` behaviour.
  """
  @spec generate_refs([Rolodex.Route.t()]) :: map()
  def generate_refs(routes) do
    routes
    |> Flow.from_enumerable()
    |> Flow.reduce(
      fn -> %{schemas: %{}, responses: %{}, request_bodies: %{}} end,
      &refs_for_route/2
    )
    |> Map.new()
  end

  defp refs_for_route(route, all_refs) do
    route
    |> unserialized_refs_for_route(all_refs)
    |> Enum.reduce(all_refs, fn
      {:schema, ref}, %{schemas: schemas} = acc ->
        %{acc | schemas: Map.put(schemas, ref, Schema.to_map(ref))}

      {:response, ref}, %{responses: responses} = acc ->
        %{acc | responses: Map.put(responses, ref, Response.to_map(ref))}

      {:request_body, ref}, %{request_bodies: request_bodies} = acc ->
        %{acc | request_bodies: Map.put(request_bodies, ref, RequestBody.to_map(ref))}
    end)
  end

  # Looks at the route fields where users can provide refs that it now needs to
  # serialize. Performs a DFS on each field to collect any unserialized refs. We
  # look at both the refs in the maps of data, PLUS refs nested within the
  # responses/schemas themselves. We recursively traverse this graph until we've
  # collected all unseen refs for the current context.
  defp unserialized_refs_for_route(route, all_refs) do
    serialized_refs = serialized_refs_list(all_refs)

    route
    |> Map.take(@route_fields_with_refs)
    |> Enum.reduce(MapSet.new(), fn {_, field}, acc ->
      collect_unserialized_refs(field, acc, serialized_refs)
    end)
    |> Enum.to_list()
  end

  defp collect_unserialized_refs(field, result, serialized_refs) when is_map(field) do
    field
    |> Field.get_refs()
    |> Enum.reduce(result, &collect_ref(&1, &2, serialized_refs))
  end

  defp collect_unserialized_refs(ref, result, serialized_refs) when is_atom(ref) do
    case Field.get_ref_type(ref) do
      :schema ->
        ref
        |> Schema.get_refs()
        |> Enum.reduce(result, &collect_ref(&1, &2, serialized_refs))

      :response ->
        ref
        |> Response.get_refs()
        |> Enum.reduce(result, &collect_ref(&1, &2, serialized_refs))

      :request_body ->
        ref
        |> RequestBody.get_refs()
        |> Enum.reduce(result, &collect_ref(&1, &2, serialized_refs))

      :error ->
        result
    end
  end

  defp collect_unserialized_refs(_, acc, _), do: acc

  # If the current schema ref is unserialized, add to the MapSet of unserialized
  # refs, and then continue the recursive traversal
  defp collect_ref(ref, result, serialized_refs) do
    ref_type = Field.get_ref_type(ref)

    cond do
      {ref_type, ref} in (Enum.to_list(result) ++ serialized_refs) ->
        result

      ref_type in [:schema, :response, :request_body] ->
        result = MapSet.put(result, {ref_type, ref})
        collect_unserialized_refs(ref, result, serialized_refs)

      true ->
        result
    end
  end

  defp serialized_refs_list(%{
         schemas: schemas,
         responses: responses,
         request_bodies: request_bodies
       }) do
    serialized_schema_refs =
      schemas
      |> Map.keys()
      |> Enum.map(&{:schema, &1})

    serialized_response_refs =
      responses
      |> Map.keys()
      |> Enum.map(&{:response, &1})

    serialized_request_body_refs =
      request_bodies
      |> Map.keys()
      |> Enum.map(&{:request_body, &1})

    serialized_schema_refs ++ serialized_response_refs ++ serialized_request_body_refs
  end
end
