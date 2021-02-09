defmodule TutoKbrwStack do
  @moduledoc """
  Documentation for `TutoKbrwStack`.
  """

  use Application

  @impl true
  def start(_type, _args) do
    Server.Supervisor.start_link(name: Server.Supervisor)
  end
end
