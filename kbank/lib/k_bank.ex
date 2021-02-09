defmodule KBank do
  @moduledoc """
  Documentation for `KBank`.
  """
  use Application

  @impl true
  def start(_type, _args) do
    KBank.Supervisor.start_link(name: KBank.Supervisor)
  end
end
