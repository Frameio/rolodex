defmodule Rolodex.ConfigTest do
  use ExUnit.Case

  alias Rolodex.{Config, PipelineConfig, WriterConfig}

  describe "#new/1" do
    test "It parses nested writer config into a struct to set defaults" do
      default_config = Config.new()
      default_writer_config = WriterConfig.new()

      assert match?(%Config{writer: ^default_writer_config}, default_config)

      config = Config.new(writer: [file_name: "testing.json"])
      writer_config = WriterConfig.new(file_name: "testing.json")

      assert match?(%Config{writer: ^writer_config}, config)
    end

    test "It parses pipeline configs into structs to set defaults" do
      config =
        Config.new(
          pipelines: [
            api: [
              body: [
                id: :uuid
              ]
            ]
          ]
        )

      assert match?(%Config{pipelines: %{api: %PipelineConfig{body: %{id: :uuid}}}}, config)
    end
  end
end
