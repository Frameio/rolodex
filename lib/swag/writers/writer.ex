defmodule Swag.Writer do
  @moduledoc """
  Takes a Swag.t and converts it into a desireable output.
  """

  @callback write(pid, String.t()) :: :ok
  @callback init(Swag.Config.t()) :: String.t()
  @callback close(pid) :: :ok | {:error, any}
end
