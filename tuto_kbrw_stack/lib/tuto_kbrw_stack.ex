defmodule TutoKbrwStack do
  @moduledoc """
  Documentation for `TutoKbrwStack`.
  """

  use Application

  @impl true
  def start(_type, _args) do
    Server.Supervisor.start_link(name: Server.Supervisor)

    Application.put_env(
      :reaxt,
      :global_config,
      Map.merge(
        Application.get_env(:reaxt, :global_config),
        %{localhost: "http://localhost:4004"}
      )
    )

    Reaxt.reload()
  end
end
