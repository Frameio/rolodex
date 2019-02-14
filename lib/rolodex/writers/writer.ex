defmodule Rolodex.Writer do
  @moduledoc """
  A behavior to write to arbitrary entities.
  """

  @doc """
  Should implement a way to write to a process.
  """
  @callback write(IO.device(), String.t()) :: :ok

  @doc """
  Returns a io_device that you can write to.
  """
  @callback init(Rolodex.Config.t()) :: {:ok, IO.device()} | {:error, any}

  @doc """
  Closes the given pid
  """
  @callback close(IO.device()) :: :ok | {:error, any}
end
