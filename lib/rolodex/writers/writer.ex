defmodule Rolodex.Writer do
  @moduledoc """
  A behavior to write to arbitrary entities.
  """

  @doc """
  Should implement a way to write to a `IO.device()`.
  """
  @callback write(IO.device(), String.t()) :: :ok

  @doc """
  Returns an open `IO.device()` for writing.
  """
  @callback init(list() | map()) :: {:ok, IO.device()} | {:error, any}

  @doc """
  Closes the given `IO.device()`.
  """
  @callback close(IO.device()) :: :ok | {:error, any}
end
