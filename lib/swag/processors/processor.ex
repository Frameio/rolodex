defmodule Swag.Processor do
  @moduledoc """
  Takes a Swag.t and converts it into a desireable output.
  """

  @callback process(Swag.t) :: {:ok, term} | {:error, String.t}
end
