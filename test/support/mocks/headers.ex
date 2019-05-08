defmodule Rolodex.Mocks.PaginationHeaders do
  use Rolodex.Headers

  headers "PaginationHeaders" do
    header("total", :integer, desc: "Total entries to be retrieved")

    header("per-page", :integer,
      desc: "Total entries per page of results",
      required: true
    )
  end
end

defmodule Rolodex.Mocks.RateLimitHeaders do
  use Rolodex.Headers

  headers "RateLimitHeaders" do
    header("limited", :boolean, desc: "Have you been rate limited")
  end
end
