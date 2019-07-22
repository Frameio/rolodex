defmodule Rolodex.Router.RouteInfo do
  @moduledoc false

  import Rolodex.Utils, only: [to_struct: 2]

  defstruct [
    :action,
    :controller,
    :desc,
    :metadata,
    :path,
    :pipe_through,
    :verb
  ]

  @type t :: %__MODULE__{
          action: atom(),
          controller: module(),
          desc: binary(),
          metadata: map() | list() | nil,
          path: binary(),
          pipe_through: list(),
          verb: atom()
        }

  def new(params), do: params |> Map.new() |> to_struct(__MODULE__)

  def from_route_info(
        %{plug: controller, plug_opts: action, route: path, pipe_through: pipe_through},
        verb
      ) do
    %__MODULE__{
      controller: controller,
      action: action,
      path: path,
      verb: verb,
      pipe_through: pipe_through
    }
  end

  def from_route_info(_, _), do: nil

  def from_router_tree(%{
        plug: controller,
        opts: action,
        path: path,
        verb: verb,
        pipe_through: pipe_through
      }) do
    %__MODULE__{
      controller: controller,
      action: action,
      path: path,
      verb: verb,
      pipe_through: pipe_through
    }
  end

  def from_router_tree(_), do: nil
end
