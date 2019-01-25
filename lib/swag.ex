defmodule Swag do
  @moduledoc """
  Documentation for Swag.
  """

  alias Swag.{Config, Route}

  @spec generate_documentation(Config.t()) :: :ok | {:error, any()}
  def generate_documentation(config) do
    routes = generate_routes(config)
    schemas = generate_schemas(routes)
    processed = process(config, routes, schemas)

    write(config, processed)
  end

  @spec generate_routes(Config.t()) :: [Route.t()]
  def generate_routes(%Config{router: router} = config) do
    router.__routes__()
    |> Flow.from_enumerable()
    |> Flow.map(&Route.generate_route(&1, config))
    |> Flow.reject(fn route ->
      case config.filter do
        :none -> false
        filter -> route == filter
      end
    end)
    |> Enum.to_list()
  end

  @spec generate_schemas([Route.t()]) :: map()
  def generate_schemas(routes) do
    routes
    |> Flow.from_enumerable()
    |> Flow.reduce(fn -> %{} end, &generate_schemas/2)
    |> Map.new()
  end

  @spec process(Config.t(), [Route.t()], map()) :: String.t()
  def process(%Config{processor: processor} = config, routes, schemas) do
    processor.process(config, routes, schemas)
  end

  @spec write(Config.t(), String.t()) :: :ok | {:error, any()}
  def write(%Config{writer: writer} = config, processed) do
    writer = Keyword.fetch!(writer, :module)

    with {:ok, device} <- writer.init(config),
         :ok <- writer.write(device, processed),
         :ok <- writer.close(device) do
      :ok
    else
      err -> err
    end
  end

  defp generate_schemas(%Route{responses: responses}, acc) do
    Enum.reduce(responses, acc, fn {_, v}, refs ->
      case can_generate_schema?(v) do
        true -> Map.put_new(refs, v, v.to_json_schema())
        false -> refs
      end
    end)
  end

  defp can_generate_schema?(mod) when is_atom(mod) do
    :erlang.function_exported(mod, :to_json_schema, 0)
  end

  defp can_generate_schema?(_), do: false
end
