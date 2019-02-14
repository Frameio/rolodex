defmodule Rolodex.Writers.Mock do
  @behaviour Rolodex.Writer

  @impl Rolodex.Writer
  def init(_), do: {:ok, :stdio}

  @impl Rolodex.Writer
  def write(io_device, content), do: IO.write(io_device, content)

  @impl Rolodex.Writer
  def close(:stdio), do: :ok
end
