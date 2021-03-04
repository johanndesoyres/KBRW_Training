defimpl ExFSM.Machine.State, for: Map do
  def state_name(order), do: String.to_atom(order["status"]["state"])

  def set_state_name(order, name),
    do:
      Kernel.get_and_update_in(order["status"]["state"], fn state ->
        {state, Atom.to_string(name)}
      end)

  def handlers(order) do
    {fsm, _} = Rules.apply_rules(order, [])
    fsm
  end
end
