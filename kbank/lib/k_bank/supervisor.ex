defmodule KBank.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(opts) do
    {:ok, _} = Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [{KBank.Account, name: KBank.Account}]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
