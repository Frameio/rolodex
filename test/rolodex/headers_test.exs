defmodule Rolodex.HeadersTest do
  use ExUnit.Case

  alias Rolodex.Headers
  alias Rolodex.Mocks.PaginationHeaders

  doctest Headers

  describe "#headers/2 macro" do
    test "It generates headers metadata" do
      assert PaginationHeaders.__headers__(:name) == "PaginationHeaders"

      assert PaginationHeaders.__headers__(:headers) == %{
               "total" => %{type: :integer, desc: "Total entries to be retrieved"},
               "per-page" => %{
                 type: :integer,
                 desc: "Total entries per page of results",
                 required: true
               }
             }
    end
  end

  describe "#is_headers_module?/1" do
    test "It returns the expected result" do
      assert Headers.is_headers_module?(PaginationHeaders)
      refute Headers.is_headers_module?(UnusedAlias)
    end
  end

  describe "#to_map/1" do
    test "It returns the serialized headers" do
      assert Headers.to_map(PaginationHeaders) == %{
               "total" => %{type: :integer, desc: "Total entries to be retrieved"},
               "per-page" => %{
                 type: :integer,
                 desc: "Total entries per page of results",
                 required: true
               }
             }
    end
  end
end
