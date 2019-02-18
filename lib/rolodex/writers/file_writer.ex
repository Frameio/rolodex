defmodule Rolodex.Writers.FileWriter do
  @behaviour Rolodex.Writer

  alias Rolodex.{Config, WriterConfig}

  @impl Rolodex.Writer
  def init(config) do
    with {:ok, file_name} <- fetch_file_name(config),
         {:ok, cwd} <- File.cwd(),
         full_path <- Path.join([cwd, file_name]),
         :ok <- File.touch(full_path) do
      File.open(full_path, [:write])
    end
  end

  @impl Rolodex.Writer
  def write(io_device, content) do
    IO.write(io_device, content)
  end

  @impl Rolodex.Writer
  def close(io_device) do
    File.close(io_device)
  end

  defp fetch_file_name(%Config{writer: %WriterConfig{file_name: file_name}}) do
    case file_name do
      "" -> {:error, :file_name_missing}
      nil -> {:error, :file_name_missing}
      path -> {:ok, path}
    end
  end
end
