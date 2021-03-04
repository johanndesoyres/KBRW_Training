defimpl ExFSM.Machine.State, for: :atom do
  def state_name(door), do: door
  def set_state_name(door, name), do: name
  def handlers(order) do
    [MyFSM]
  end
end

defmodule Elixir.Door do
  use ExFSM
   deftrans closed({:open_door,_params},state) do
     {:next_state,:opened,state}
   end
   @to [:closed]
   deftrans opened({:close_door,_params},state) do
     then = :closed
     {:next_state,then,state}
  end
 end

 Door.fsm
