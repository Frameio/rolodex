defmodule Swag.Processor do
  @moduledoc """
  Takes a Swag.t and converts it into a desireable output.
  """

  @callback process(Swag.t, Swag.Config.t) :: String.t
  @callback init(Swag.Config.t) :: String.t
  @callback finish(Swag.Config.t) :: String.t
end
