defmodule Rules do
  use Rulex
  defrule(paypal_fsm(%{payment_method: :paypal} = order, acc), do: {:ok, [FSM.Paypal | acc]})
  defrule(stripe_fsm(%{payment_method: :stripe} = order, acc), do: {:ok, [FSM.Stripe | acc]})
  defrule(delivery_fsm(param, acc), do: {:ok, [FSM.Delivery | acc]})
end
