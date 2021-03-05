defmodule Pay do
  use GenServer

  def process_payment(order_id) do
    start_link(order_id)
    response = pay(order_id)
    case response do
      :action_unavailable -> response
      _ ->
        body = response |> Poison.encode!()
        new_order = Server.Riak.post_object("orders", order_id, body) |> Poison.decode!()

        case new_order do
          %{} -> new_order
          _ -> :action_unavailable
        end
    end
  end

  def start_link(order_id) do
    GenServer.start_link(
      __MODULE__,
      order_id,
      name: String.to_atom(order_id)
    )
  end

  # Client API

  def pay(order_id) do
    GenServer.call(String.to_atom(order_id), :process_payment)
  end

  def stop(order_id) do
    GenServer.stop(String.to_atom(order_id), :normal, :infinity)
  end

  # Callbacks

  @impl true
  def init(order_id) do
    request = Server.Riak.get_object("orders", order_id)
    case request do
      'not found\n' -> {:ok, :action_unavailable}
      _ -> {:ok, Poison.decode!(request)}
    end
  end

  @impl true
  def handle_call(:process_payment, _from, order) do
    case order do
      :action_unavailable -> {:reply, order, order}
      _ ->
        {:next_state, {_old_state, updated_order}} =
          ExFSM.Machine.event(order, {:process_payment, []})

        {:next_state, {_old_state, final_order}} =
            ExFSM.Machine.event(updated_order, {:verification, []})

        {:reply, final_order, final_order}
    end
  end

  #@impl true
  #def handle_call(:exit, _from, order) do
  #  {:stop, :finish_payment, order, order}
  #end
end
