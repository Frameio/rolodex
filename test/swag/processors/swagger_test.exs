defmodule Swag.Processors.SwaggerTest do
  use ExUnit.Case
  alias Swag.Processors.Swagger

  describe "#process/2" do
    test "It takes a swag struct and converts it into a swagger formatted json fragment" do
      swag = %Swag{
        description: "It does a thing",
        responses: %{200 => %{}},
        path: "/foo",
        verb: :get,
      }

      actual = Swagger.process(swag, %{})
      expected = Jason.encode!(
        %{
          "/foo" => %{
            "get" => %{
              "description" => "It does a thing",
              "responses" => %{200 => %{}}
            },
          },
        }
      )

      assert actual == expected
    end
  end

  describe "#init/1" do
    test "It returns a json fragment of things that should be written once and sets the open api version" do
      config = Swag.Config.new(description: "foo", title: "bar", version: "1")
      assert Swagger.init(config) == """
      {\"info\":{
        \"description\":\"foo\",
        \"title\":\"bar\",
        \"version\":\"1\"},
      \"openapi\":\"3.0.0\",
      \"paths\":[
      """
    end
  end

  describe "#finalize/1" do
    test "It closes the json fragment" do
      assert Swagger.finalize(:any) == """
      ]}
      """
    end
  end
end
