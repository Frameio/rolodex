defmodule Rolodex.Mocks.TestRouter do
  use Phoenix.Router

  scope "/api", Rolodex.Mocks do
    get("/demo", TestController, :index)
    post("/demo/:id", TestController, :conflicted)
    put("/demo/:id", TestController, :with_bare_maps)
    delete("/demo/:id", TestController, :undocumented)

    # This route action does not exist
    put("/demo/:id", TestController, :missing_action)
  end
end
