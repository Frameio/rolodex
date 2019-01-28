defmodule Rolodex.RouteTest do
  use ExUnit.Case

  alias Phoenix.Router
  alias Rolodex.{Route, Config, PipelineConfig}
  alias Rolodex.Mocks.TestController

  describe "#fetch_route_docs/1" do
    test "It returns a tuple with the description and doc metadata attached to the controller action" do
      {desc, metadata} = Route.fetch_route_docs(%Router.Route{plug: TestController, opts: :index})

      assert desc == %{"en" => "It's a test!"}

      assert metadata == %{
               headers: %{foo: :bar},
               body: %{foo: :bar},
               query_params: %{"foo" => "bar"},
               responses: %{200 => Rolodex.Mocks.User},
               metadata: %{public: true},
               tags: ["foo", "bar"]
             }
    end
  end

  describe "#get_pipeline_config/2" do
    setup [:setup_config]

    test "It returns an empty Rolodex.PipelineConfig if the current route scope has no pipe_throughs",
         %{config: config} do
      result = Route.get_pipeline_config(%Router.Route{pipe_through: nil}, config)

      assert result == %PipelineConfig{
               body: %{},
               headers: %{},
               query_params: %{}
             }
    end

    test "It returns an empty Rolodex.PipelineConfig if there is no shared config defined" do
      result = Route.get_pipeline_config(%Router.Route{pipe_through: [:api]}, Config.new())

      assert result == %PipelineConfig{
               body: %{},
               headers: %{},
               query_params: %{}
             }
    end

    test "It collects all shared pipeline config data for all route pipe_throughs", %{
      config: config
    } do
      result = Route.get_pipeline_config(%Router.Route{pipe_through: [:api, :web]}, config)

      assert result == %PipelineConfig{
               body: %{foo: :bar},
               headers: %{foo: :bar},
               query_params: %{"foo" => "bar", "zig" => "zag"}
             }
    end
  end

  describe "#parse_description/2" do
    test "It returns an empty string when `:none`" do
      assert Route.parse_description(:none, Config.new()) == ""
    end

    test "It returns a string if provided" do
      assert Route.parse_description("hello world", Config.new()) == "hello world"
    end

    test "It returns the description for the configured locale" do
      result = Route.parse_description(%{"en" => "hello world"}, Config.new(locale: "en"))
      assert result == "hello world"
    end
  end

  describe "#new/2" do
    setup [:setup_config]

    test "It builds a new Rolodex.Route for the specified controller action", %{config: config} do
      phoenix_route = %Router.Route{
        plug: TestController,
        opts: :index,
        path: "/v2/test",
        pipe_through: [],
        verb: :get
      }

      result = Route.new(phoenix_route, config)

      assert result == %Route{
               description: "It's a test!",
               headers: %{foo: :bar},
               body: %{foo: :bar},
               query_params: %{"foo" => "bar"},
               responses: %{200 => Rolodex.Mocks.User},
               metadata: %{public: true},
               tags: ["foo", "bar"],
               path: "/v2/test",
               pipe_through: [],
               verb: :get
             }
    end

    test "It merges controller action params into pipeline params", %{config: config} do
      phoenix_route = %Router.Route{
        plug: TestController,
        opts: :index,
        path: "/v2/test",
        pipe_through: [:web],
        verb: :get
      }

      result = Route.new(phoenix_route, config)

      assert result == %Route{
               description: "It's a test!",
               headers: %{foo: :bar},
               body: %{foo: :bar},
               query_params: %{"foo" => "bar", "zig" => "zag"},
               responses: %{200 => Rolodex.Mocks.User},
               metadata: %{public: true},
               tags: ["foo", "bar"],
               path: "/v2/test",
               pipe_through: [:web],
               verb: :get
             }
    end

    test "It handles an undocumented route" do
      phoenix_route = %Router.Route{
        plug: TestController,
        opts: :undocumented,
        path: "/v2/test",
        pipe_through: [],
        verb: :post
      }

      assert Route.new(phoenix_route, Config.new()) == %Route{
               description: "",
               headers: %{},
               body: %{},
               query_params: %{},
               responses: %{},
               metadata: %{},
               tags: [],
               path: "/v2/test",
               pipe_through: [],
               verb: :post
             }
    end
  end

  def setup_config(_) do
    config =
      Config.new(%{
        pipelines: %{
          api: %{
            headers: %{foo: :bar},
            query_params: %{"foo" => "bar"}
          },
          web: %{
            body: %{foo: :bar},
            headers: %{foo: :bar},
            query_params: %{"foo" => "bar", "zig" => "zag"}
          },
          socket: %{
            headers: %{bar: :baz}
          }
        }
      })

    [config: config]
  end
end
