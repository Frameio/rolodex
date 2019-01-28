defmodule Mix.Tasks.GenDocs do
  use Mix.Task

  def run(_args) do
    Application.get_all_env(:rolodex)
    |> Rolodex.Config.new()
    |> Rolodex.run()
  end
end
