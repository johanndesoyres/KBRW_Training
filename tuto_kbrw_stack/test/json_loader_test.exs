defmodule JsonLoaderTest do
  use ExUnit.Case, async: true

  setup context do
    _ = start_supervised!({Server.Database, name: context.test})
    %{database: context.test}
  end

  test "Load Json chunk0", %{database: database} do
    JsonLoader.load_to_database(database, "../../orders_dump/orders_chunk0.json")
    assert {:ok, %{}} = Server.Database.lookup(database, "nat_order000147815")
  end

  test "Load Json chunk1", %{database: database} do
    JsonLoader.load_to_database(database, "../../orders_dump/orders_chunk1.json")
    assert {:ok, %{}} = Server.Database.lookup(database, "nat_order000147669")
  end

  test "Load dummy orders", %{database: database} do
    JsonLoader.load_to_database(database, "../../orders_dump/dummy_orders.json")
    assert {:ok, %{}} = Server.Database.lookup(database, "toto")
  end
end
