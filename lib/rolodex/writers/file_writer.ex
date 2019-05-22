defmodule Rolodex.Writers.FileWriter do
  @behaviour Rolodex.Writer

  @impl Rolodex.Writer
  def init(opts) do
    with {:ok, file_name} <- fetch_file_name(opts),
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

  defp fetch_file_name(opts) when is_list(opts) do
    opts
    |> Map.new()
    |> fetch_file_name()
  end

  defp fetch_file_name(%{file_name: name}) when is_binary(name) and name != "",
    do: {:ok, name}

  defp fetch_file_name(_), do: {:error, :file_name_missing}
end
