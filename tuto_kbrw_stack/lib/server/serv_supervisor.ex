defmodule Server.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    {:ok, _} = Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {Server.Database, name: Server.Database},
      Plug.Cowboy.child_spec(scheme: :http, plug: Server.Router, options: [port: 4004])
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
