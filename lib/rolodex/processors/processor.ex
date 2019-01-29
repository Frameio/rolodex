defmodule Rolodex.Processor do
  @moduledoc """
  Takes a Rolodex.Config.t(), a list of Rolodex.Route.t(), and a map of response
  schemas. Transforms them into a desirable output in the form of a JSON string.
  The only required function is process/3, which is responsible for coordinating
  processing and returning the formatted JSON.
  """

  @optional_callbacks process_headers: 1, process_routes: 2, process_schemas: 1

  @doc """
  Process is responsible for turning each Rolodex.t() it receives and turning it
  into a string so that it can be written.
  """
  @callback process(Rolodex.Config.t(), [Rolodex.Route.t()], schemas :: map()) :: String.t()

  @doc """
  Generates top-level metadata for the JSON output.
  """
  @callback process_headers(Rolodex.Config.t()) :: map()
  def process_headers(_), do: %{}

  @doc """
  Transforms each Rolodex.Route.t() into a map to be added to the final JSON blob.
  """
  @callback process_routes([Rolodex.Route.t()], schemas :: map()) :: list()
  def process_routes(_, _), do: []

  @doc """
  Transforms the schemas map into a map to be added to the final JSON blob.
  """
  @callback process_schemas(schemas :: map()) :: map()
  def process_schemas(_), do: %{}
end
