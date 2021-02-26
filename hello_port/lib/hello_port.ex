defmodule HelloPort do
  use GenServer

  @moduledoc """
  Documentation for `HelloPort`.
  """

  def start_link() do
    GenServer.start_link(
      __MODULE__,
      {"node hello.js", 0, cd: "/Users/user1/Documents/KBRW_Training/hello_port"},
      name: Hello
    )
  end

  # Client API

  def call(msg) do
    GenServer.call(Hello, {:call, msg})
  end

  def cast(msg) do
    GenServer.cast(Hello, {:cast, msg})
  end

  # Callbacks

  @impl true
  def init({cmd, init, opts}) do
    port = Port.open({:spawn, '#{cmd}'}, [:binary, :exit_status, packet: 4] ++ opts)
    send(port, {self(), {:command, :erlang.term_to_binary(init)}})
    {:ok, port}
  end

  @impl true
  def handle_call({:call, msg}, _from, port) do
    send(port, {self(), {:command, :erlang.term_to_binary(msg)}})

    response =
      receive do
        {^port, {:data, b}} -> :erlang.binary_to_term(b)
      end

    {:reply, response, port}
  end

  @impl true
  def handle_cast({:cast, msg}, port) do
    send(port, {self(), {:command, :erlang.term_to_binary(msg)}})
    {:noreply, port}
  end

  @impl true
  def handle_info({port, {:exit_status, 0}}, port), do: {:stop, :normal, port}
  @impl true
  def handle_info({port, {:exit_status, _}}, port), do: {:stop, :port_terminated, port}
  @impl true
  def handle_info(_, port), do: {:noreply, port}
end
