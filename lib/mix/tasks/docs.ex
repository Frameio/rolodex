defmodule Mix.Tasks.GenDocs do
  use Mix.Task
  alias Rolodex.Config

  def run(_args) do
    env = Application.get_all_env(:rolodex)

    Rolodex.Config.new(env)
    |> Rolodex.generate_documentation()
  end
end
