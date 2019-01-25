defmodule Rolodex.PipeThroughMap do
  defstruct body: %{},
            headers: %{},
            query_params: %{}

  @type t :: %__MODULE__{
          body: map,
          headers: map,
          query_params: map
        }

  def new(params \\ %{}) do
    struct(__MODULE__, params)
  end
end
