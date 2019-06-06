defmodule Rolodex.Mocks.TestRouter do
  use Phoenix.Router

  scope "/api", Rolodex.Mocks do
    get("/demo", TestController, :index)
    post("/demo/:id", TestController, :conflicted)
    put("/demo/:id", TestController, :with_bare_maps)
    delete("/demo/:id", TestController, :undocumented)

    # Multi-headed action function
    get("/multi", TestController, :multi)
    get("/nested/:nested_id/multi", TestController, :multi)

    # This action function uses schemas for query and path params plus partials
    get("/partials", TestController, :params_via_schema)

    # This route action does not exist
    put("/demo/missing/:id", TestController, :missing_action)
  end
end
