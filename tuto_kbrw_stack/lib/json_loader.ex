defmodule JsonLoader do
  def load_to_database(database, json_file) do
    File.read!(json_file)
    |> Poison.Parser.parse!(%{})
    |> Enum.map(fn order ->
      Server.Database.create(database, order["id"], Map.delete(order, "id"))
    end)
  end

  def load_to_riak(json_file) do
    order_list =
      File.read!(json_file)
      |> Poison.Parser.parse!(%{})

    order_list
    |> Stream.map(fn order ->
      Server.Riak.post_object("orders", order["id"], Poison.encode!(Map.delete(order, "id")))
    end)
    |> Stream.take(length(order_list))
    |> Enum.to_list()
  end

  def load_to_riak_v2(json_file) do
    order_list =
      File.read!(json_file)
      |> Poison.Parser.parse!(%{})

    order_list
    |> Stream.chunk_every(10)
    |> Enum.map(fn orders_chunk ->
      orders_chunk
      |> Stream.map(fn order ->
        Task.async(fn ->
          Server.Riak.post_object("orders", order["id"], Poison.encode!(Map.delete(order, "id")))
        end)
      end)
      |> Stream.map(&Task.await/1)
      |> Stream.run()
    end)
    |> Stream.run()
  end
end
