defmodule JsonLoader do
  def load_to_database(database, json_file) do
    File.read!(json_file)
    |> Poison.Parser.parse!(%{})
    |> Enum.map(fn order ->
      Server.Database.create(database, order["id"], Map.delete(order, "id"))
    end)
  end
end
