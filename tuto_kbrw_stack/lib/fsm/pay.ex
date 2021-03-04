defmodule Pay do
  use GenServer

  def process_payment(order_id) do
    start_link(order_id)
    body = pay() |> Poison.encode!()
    new_order = Server.Riak.post_object("orders", order_id, body) |> Poison.decode!()

    case new_order do
      %{} -> new_order
      _ -> :action_unavailable
    end
  end

  def start_link(order_id) do
    GenServer.start_link(
      __MODULE__,
      order_id,
      name: PayServer
    )
  end

  # Client API

  def pay() do
    GenServer.call(PayServer, :process_payment)
  end

  # Callbacks

  @impl true
  def init(order_id) do
    # FSM.Paypal.fsm()
    # FSM.Stripe.fsm()
    # FSM.Delivery.fsm()
    order = Poison.decode!(Server.Riak.get_object("orders", order_id))
    {:ok, order}
  end

  @impl true
  def handle_call(:process_payment, _from, order) do
    {:next_state, {_old_state, updated_order}} =
      ExFSM.Machine.event(order, {:process_payment, []})

    {:next_state, {_old_state, final_order}} =
        ExFSM.Machine.event(updated_order, {:verification, []})

    IO.inspect(updated_order)
    {:stop, :finish_payment, final_order, final_order}
    #{:reply, updated_order, updated_order}
  end
end
