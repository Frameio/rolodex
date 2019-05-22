defmodule Mix.Tasks.Rolodex.Gen.Docs do
  use Mix.Task

  @shortdoc "Runs Rolodex to generate API docs."

  @doc false
  def run(_args) do
    IO.puts("Rolodex is compiling your docs...\n")

    Application.get_all_env(:rolodex)[:module]
    |> Rolodex.Config.new()
    |> Rolodex.run()
    |> log_result()
  end

  defp log_result(renders) do
    renders
    |> Enum.reduce([], fn
      {:ok, _}, acc -> acc
      {:error, err}, acc -> [err | acc]
    end)
    |> case do
      [] -> IO.puts("Done!")
      errs ->
        IO.puts("Rolodex failed to compile some docs with the following errors:")
        Enum.each(errs, &IO.inspect(&1))
    end
  end
end
