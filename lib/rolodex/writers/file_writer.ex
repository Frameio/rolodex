defmodule Rolodex.Writers.FileWriter do
  @behaviour Rolodex.Writer

  @impl Rolodex.Writer
  def init(config) do
    path = fetch_file_path(config)

    File.touch(path)
    File.open(path, [:write])
  end

  @impl Rolodex.Writer
  def write(io_device, content) do
    IO.write(io_device, content)
  end

  @impl Rolodex.Writer
  def close(io_device) do
    File.close(io_device)
  end

  defp fetch_file_path(config) do
    get_in(config.writer, [:config, :file_path])
  end
end
