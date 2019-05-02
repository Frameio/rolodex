defmodule Mix.Tasks.Rolodex.Gen.Docs do
  use Mix.Task

  @shortdoc "Runs Rolodex to generate API docs."

  @doc false
  def run(_args) do
    Application.get_all_env(:rolodex)[:module]
    |> Rolodex.Config.new()
    |> Rolodex.run()
  end
end
