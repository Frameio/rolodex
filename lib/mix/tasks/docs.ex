defmodule Mix.Tasks.GenDocs do
  use Mix.Task
  alias Swag.Config

  def run(_args) do
    env = Application.get_all_env(:swag)

    Swag.Config.new(env)
    |> Swag.generate_documentation()
  end
end
