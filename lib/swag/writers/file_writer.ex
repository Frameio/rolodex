defmodule Swag.Writers.FileWriter do
  @behaviour Swag.Writer

  @impl Swag.Writer
  def init(config) do
    path = Keyword.fetch!(config.writer, :write_path)

    File.touch(path)
    File.open(path)
  end

  @impl Swag.Writer
  def write(io_device, content) do
    IO.write(io_device, content)
  end

  @impl Swag.Writer
  def close(io_device) do
    File.close(io_device)
  end
end
