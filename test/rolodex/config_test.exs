defmodule Rolodex.ConfigTest do
  use ExUnit.Case

  alias Rolodex.{Config, PipelineConfig}

  defmodule BasicConfig do
    use Rolodex.Config

    def spec() do
      [
        description: "Hello world",
        title: "BasicConfig",
        version: "0.0.1",
        router: MyRouter
      ]
    end
  end

  defmodule FullConfig do
    use Rolodex.Config

    def spec() do
      [
        description: "Hello world",
        title: "BasicConfig",
        version: "0.0.1",
        router: MyRouter
      ]
    end

    def pipelines_spec() do
      [
        api: [
          auth: :JWTAuth,
          headers: ["X-Request-ID": :uuid]
        ]
      ]
    end

    def auth_spec() do
      [
        JWTAuth: [
          type: "http",
          scheme: "bearer"
        ],
        TokenAuth: [type: "oauth2"],
        OAuth: [
          type: "oauth2",
          flows: [
            authorization_code: [
              authorization_url: "https://applications.frame.io/oauth2/authorize",
              token_url: "https://applications.frame.io/oauth2/token",
              scopes: [
                "user.read",
                "account.read",
                "account.write"
              ]
            ]
          ]
        ]
      ]
    end
  end

  describe "#new/1" do
    test "It parses a basic config with no writer and pipeline overrides" do
      assert Config.new(BasicConfig) == %Config{
               description: "Hello world",
               file_name: "api.json",
               locale: "en",
               pipelines: %{},
               processor: Rolodex.Processors.Swagger,
               title: "BasicConfig",
               version: "0.0.1",
               router: MyRouter,
               writer: Rolodex.Writers.FileWriter
             }
    end

    test "It parses a full config with writer and pipeline overrides" do
      assert Config.new(FullConfig) == %Config{
               description: "Hello world",
               file_name: "api.json",
               locale: "en",
               pipelines: %{
                 api: PipelineConfig.new(headers: ["X-Request-ID": :uuid], auth: :JWTAuth)
               },
               auth: %{
                 JWTAuth: %{
                   type: "http",
                   scheme: "bearer"
                 },
                 TokenAuth: %{type: "oauth2"},
                 OAuth: %{
                   type: "oauth2",
                   flows: %{
                     authorization_code: %{
                       authorization_url: "https://applications.frame.io/oauth2/authorize",
                       token_url: "https://applications.frame.io/oauth2/token",
                       scopes: [
                         "user.read",
                         "account.read",
                         "account.write"
                       ]
                     }
                   }
                 }
               },
               processor: Rolodex.Processors.Swagger,
               title: "BasicConfig",
               version: "0.0.1",
               router: MyRouter,
               writer: Rolodex.Writers.FileWriter
             }
    end
  end
end
