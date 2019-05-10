defmodule Rolodex.Mocks.PaginationHeaders do
  use Rolodex.Headers

  headers "PaginationHeaders" do
    field("total", :integer, desc: "Total entries to be retrieved")

    field("per-page", :integer,
      desc: "Total entries per page of results",
      required: true
    )
  end
end

defmodule Rolodex.Mocks.RateLimitHeaders do
  use Rolodex.Headers

  headers "RateLimitHeaders" do
    field("limited", :boolean, desc: "Have you been rate limited")
  end
end
