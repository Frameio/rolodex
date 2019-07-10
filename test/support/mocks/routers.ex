defmodule Rolodex.Mocks.TestRouter do
  use Rolodex.Router

  router Rolodex.Mocks.TestPhoenixRouter do
    route(:get, "/api/demo")
    routes([:post, :put, :delete], "/api/demo/:id")
    get("/api/multi")
    get("/api/nested/:nested_id/multi")
    get("/api/partials")

    # This route is defined in the Phoenix router but it has no associated
    # controller action
    put("/api/demo/missing/:id")
  end
end

defmodule Rolodex.Mocks.MiniTestRouter do
  use Rolodex.Router

  router(Rolodex.Mocks.TestPhoenixRouter, do: get("/api/demo"))
end
