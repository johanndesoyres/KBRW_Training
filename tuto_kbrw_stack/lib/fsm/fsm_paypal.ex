defmodule FSM.Paypal do
  use ExFSM

  deftrans init({:process_payment, []}, order) do
    {:next_state, :not_verified, order}
  end

  deftrans not_verified({:verification, []}, order) do
    {:next_state, :finished, order}
  end
end
