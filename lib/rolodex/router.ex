defmodule Rolodex.Router do
  @moduledoc """
  Macros for defining API routes that Rolodex should document. Functions for
  serializing these routes into fully formed docs metadata.

  A Rolodex Router is the entry point when Rolodex is compiling your docs. You
  provide the router with two things:

    1) A Phoenix Router
    2) A list of API paths (HTTP action + full URI path)

  Rolodex then looks up the controller action function associated with each API
  path, collects the doc annotations for each, and serializes it all to your docs
  output of choice.

  ## Example

      defmodule MyRolodexRouter do
        use Rolodex.Router

        alias MyWebApp.PhoenixRouter

        router PhoenixRouter do
          # Can use macros that pair with HTTP actions, just like in Phoenix
          get "/api/users"
          post "/api/users"
          put "/api/users/:id"
          patch "/api/users/:id"
          delete "/api/users/:id"
          head "/api/users/:id"
          options "/api/users/:id"

          # Our can use the more verbose route/2 macro
          route :get, "/api/users"

          # Use routes/2 to define multiple routes that use the same path
          routes [:put, :patch, :delete], "/api/users/:id"
        end
      end
  """

  alias Rolodex.Utils
  alias Rolodex.Router.RouteInfo

  defmacro __using__(_) do
    quote do
      import Rolodex.Router, only: :macros
    end
  end

  @doc """
  Opens up a definition for a Rolodex router. Used to define which routes Rolodex
  should document.

      router MyApp.MyPhoenixRouter do
        get "/api/health"

        get "/api/users"
        post "/api/users"
        put "/api/users/:id"
      end
  """
  defmacro router(phoenix_router, do: block) do
    quote do
      Module.register_attribute(__MODULE__, :routes, accumulate: true)

      unquote(block)

      def __router__(:phoenix_router), do: unquote(phoenix_router)
      def __router__(:routes), do: @routes
    end
  end

  @doc """
  Defines a set of routes with different HTTP action verbs at the same path to document

      routes [:get, :put, :delete], "/api/entity/:id"
  """
  defmacro routes(verbs, path) when is_list(verbs) do
    quote do
      unquote(Enum.map(verbs, &set_route(&1, path)))
    end
  end

  @doc """
  Defines a route with the given HTTP action verb and path to document

      route :get, "/api/entity/:id"
  """
  defmacro route(verb, path) when is_atom(verb), do: set_route(verb, path)

  @doc """
  Defines an HTTP GET route at the given path to document

      get "/api/entity/:id"
  """
  defmacro get(path), do: set_route(:get, path)

  @doc """
  Defines an HTTP POST route at the given path to document

      post "/api/entity"
  """
  defmacro post(path), do: set_route(:post, path)

  @doc """
  Defines an HTTP PUT route at the given path to document

      put "/api/entity/:id"
  """
  defmacro put(path), do: set_route(:put, path)

  @doc """
  Defines an HTTP PATCH route at the given path to document

      patch "/api/entity/:id"
  """
  defmacro patch(path), do: set_route(:patch, path)

  @doc """
  Defines an HTTP DELETE route at the given path to document

      delete "/api/entity/:id"
  """
  defmacro delete(path), do: set_route(:delete, path)

  @doc """
  Defines an HTTP HEAD route at the given path to document

      head "/api/entity/:id"
  """
  defmacro head(path), do: set_route(:head, path)

  @doc """
  Defines an HTTP OPTIONS route at the given path to document

      options "/api/entity/:id"
  """
  defmacro options(path), do: set_route(:options, path)

  defp set_route(verb, path) do
    quote do
      @routes {unquote(verb), unquote(path)}
    end
  end

  @doc """
  Collects all the routes defined in a `Rolodex.Router` into a list of fully
  serialized `Rolodex.Route` structs.
  """
  @spec build_routes(module(), Rolodex.Config.t()) :: [Rolodex.Route.t()]
  def build_routes(router_mod, config) do
    phoenix_router = router_mod.__router__(:phoenix_router)

    router_mod.__router__(:routes)
    |> Enum.reduce([], fn {verb, path}, routes ->
      # If Rolodex can't find a matching Phoenix route OR if the associated
      # controller action has no doc annotation, `build_route/4` will return `nil`
      # and we strip it from the results
      case build_route(verb, path, phoenix_router, config) do
        nil -> routes
        route -> [route | routes]
      end
    end)
  end

  defp build_route(verb, path, phoenix_router, config) do
    phoenix_router
    |> build_route_info(verb, path)
    |> with_doc_annotation()
    |> Rolodex.Route.new(config)
  end

  # Backwards compatibility logic for fetching Phoenix route info:
  #
  #   1.4.0 ~ 1.4.7 — Lookup via private router tree
  #   >= 1.4.7 — Use publicly supported `Phoenix.Router.route_info/4`
  defp build_route_info(phoenix_router, verb, path) do
    case function_exported?(Phoenix.Router, :route_info, 4) do
      true ->
        http_action_string = verb |> Atom.to_string() |> String.upcase()

        phoenix_router
        |> Phoenix.Router.route_info(http_action_string, path, "")
        |> RouteInfo.from_route_info(verb)

      false ->
        phoenix_router.__routes__()
        |> Enum.find(fn
          %{verb: ^verb, path: ^path} -> true
          _ -> false
        end)
        |> RouteInfo.from_router_tree()
    end
  end

  defp with_doc_annotation(%RouteInfo{controller: controller, action: action} = info) do
    case Utils.fetch_doc_annotation(controller, action) do
      {:error, :not_found} -> nil
      {:ok, desc, metadata} -> %{info | desc: desc, metadata: metadata}
    end
  end

  defp with_doc_annotation(_), do: nil
end
