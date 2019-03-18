defmodule Rolodex.Processor do
  @moduledoc """
  Takes a `Rolodex.Config.t()`, a list of `Rolodex.Route.t()`, and a map of shared
  `Rolodex.Schema` modules. Transforms them into a `String.t()`, formatted for
  the destination (e.g. Swagger JSON).

  The only required function is `process/3`, which is responsible for coordinating
  processing and returning the formatted string.
  """

  @optional_callbacks process_headers: 1, process_routes: 2, process_refs: 1

  @doc """
  Process is responsible for turning each `Rolodex.Route.t()` it receives and
  turning it into a string so that it can be written.
  """
  @callback process(Rolodex.Config.t(), [Rolodex.Route.t()], serialized_refs :: map()) ::
              String.t()

  @doc """
  Generates top-level metadata for the output.
  """
  @callback process_headers(Rolodex.Config.t()) :: map()
  def process_headers(_), do: %{}

  @doc """
  Transforms the routes.
  """
  @callback process_routes([Rolodex.Route.t()], Rolodex.Config.t()) :: map()
  def process_routes(_, _), do: %{}

  @doc """
  Transforms the shared request body, response, and schema refs
  """
  @callback process_refs(refs :: map()) :: map()
  def process_refs(_), do: %{}
end
