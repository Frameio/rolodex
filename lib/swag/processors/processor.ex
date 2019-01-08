defmodule Swag.Processor do
  @moduledoc """
  Takes a Swag.t and converts it into a desireable output. The only function you
  really need to implement is process/2. init/1 and finalize/1 are used to
  surround the data thats processed with things that you only want to do at the
  beginning or the end of the file respectively.
  """

  @optional_callbacks init: 1, finalize: 1

  @doc """
  Process is responsible for turning each Swag.t() it receives and turning it
  into a string so that it can be written.
  """
  @callback process(Swag.t(), Swag.Config.t()) :: String.t()

  @doc """
  Init is responsible for returning a string that should get written at the top
  of the file. In the case of swagger, init returns information such as
  `version`, `title`, and `description`. Keep in mind that this function may not
  return valid json. The only requirement is that it's a string.
  """
  @callback init(Swag.Config.t()) :: String.t()

  @doc """
  Like init, finalize is to put anything that needs to go at the end of the
  document.
  """
  @callback finalize(Swag.Config.t()) :: String.t()

  def init(_), do: ""
  def finalize(_), do: ""
end
