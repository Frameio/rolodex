defmodule Mix.Tasks.Rolodex do
  use Mix.Task

  @shortdoc "Prints Rolodex help information"

  @moduledoc """
  Prints all available Rolodex tasks.

      mix rolodex
  """

  @doc false
  def run(_args) do
    Mix.shell().info("\nAvailable Rolodex Tasks:\n")
    Mix.Tasks.Help.run(["--search", "rolodex."])
  end
end
