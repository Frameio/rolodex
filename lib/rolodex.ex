defmodule Rolodex do
  @moduledoc """
  Rolodex inspects a Phoenix Router and transforms @doc annotations on your
  controller actions into a JSON blob of documentation in the format of your
  choice.

  `Rolodex.run/1` encapsulates the full doc generation process. When run, it
  will:

  1) Traverse your Phoenix Router
  2) Collect route documentation for all controller actions
  3) Resolve the shape of the action responses
  4) Combine these pieces with project metadata into a data format of your
  choosing (e.g. Swagger OpenAPI)
  4) Encode the blob into a JSON string
  5) And finally, write it out to the destination of your choosing.

  See `Rolodex.Config` for more information about how to configure Rolodex doc
  generation.

  ## A high level example

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
        headers: %{foo: :bar},
        body: %{foo: :bar},
        query_params: %{"foo" => "bar"},
        responses: %{200 => MyResponse},
        metadata: %{public: true},
        tags: ["foo", "bar"]
      ]
      @doc "My index action"
      def index(conn, _), do: conn
    end

    # Your response schema
    defmodule MyResponse do
      object "MyResponse", type: :schema, desc: "A response" do
        field(:id, :uuid)
        field(:name, :string, desc: "The response name")
      end
    end

    # In mix.exs
    config :rolodex,
      title: "MyApp",
      description: "An example",
      version: "1.0.0",
      router: MyRouter,
      pipelines: %{
        api: %{
          headers: %{auth: true}
        }
      }

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
            "headers" => %{"auth" => true, "foo" => "bar"},
            "body" => %{"foo" => "bar"},
            "query_params" => %{"foo" => "bar"},
            "responses" => %{
              "200" => %{
                "ref" => "#/components/schemas/MyResponse"
              }
            },
            "metadata" => %{"public" => true},
            "tags" => ["foo", "bar"]
          }
        }
      },
      "components" => %{
        "schemas" => %{
          "MyResponse" => %{
            "type" => "object",
            "description" => "A response",
            "properties" => %{
              "id" => %{"type" => "string", "format" => "uuid"},
              "name" => %{"type" => "string", "description" => "The response name"}
            }
          }
        }
      }
    }
  """

  alias Rolodex.{Config, Route, Utils}

  @doc """
  Runs Rolodex and writes out documentation JSON to the specified destination
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
      err -> err
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
    schemas = generate_schemas(routes)
    processor.process(config, routes, schemas)
  end

  @doc """
  Inspects the Phoenix Router provided in your `Rolodex.Config`. Iterates
  through the list of routes to generate a `Rolodex.Route` for each.

  If you have a `filter` set in your config, it will filter out any routes that
  match the filter.
  """
  @spec generate_routes(Rolodex.Config.t()) :: [Rolodex.Route.t()]
  def generate_routes(%Config{router: router} = config) do
    router.__routes__()
    |> Flow.from_enumerable()
    |> Flow.map(&Route.new(&1, config))
    |> Flow.reject(fn route ->
      case config.filter do
        :none -> false
        # TODO(billyc): Need to rework/improve filtering i think...
        filter -> route == filter
      end
    end)
    |> Enum.to_list()
  end

  @doc """
  Inspects the responses for reach `Rolodex.Route`. For any response that is a
  `Rolodex.Object`, we resolve the schema mappings into the final result.
  """
  @spec generate_schemas([Rolodex.Route.t()]) :: map()
  def generate_schemas(routes) do
    routes
    |> Flow.from_enumerable()
    |> Flow.reduce(fn -> %{} end, fn %Route{responses: responses}, acc ->
      Enum.reduce(responses, acc, &generate_schema/2)
    end)
    |> Map.new()
  end

  defp generate_schema({_, mod}, refs) do
    case Utils.can_generate_schema?(mod) && !Map.has_key?(refs, mod) do
      true -> generate_schema(mod, refs)
      false -> refs
    end
  end

  defp generate_schema(mod, refs) do
    refs = Map.put(refs, mod, mod.to_schema_map())

    # Ensure we also collect any nested objects
    mod.nested_objects()
    |> Enum.reduce(refs, fn nested, acc ->
      Map.put_new(acc, nested, nested.to_schema_map())
    end)
  end
end
