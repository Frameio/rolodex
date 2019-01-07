defmodule Swag.Writers.FileWriter do
  def init(config) do
    path = Keyword.fetch!(config.writer, :write_path)

    File.touch(path)
    File.open(path)
  end

  def write(io_device, content) do
    IO.write(io_device, content)
  end

  def close(io_device) do
    File.close(io_device)
  end
end
