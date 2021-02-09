defmodule Server.DatabaseTest do
  use ExUnit.Case, async: true

  setup context do
    _ = start_supervised!({Server.Database, name: context.test})
    %{database: context.test}
  end

  test "create val", %{database: database} do
    assert Server.Database.lookup(database, "first val") == :error

    Server.Database.create(database, "first val", "hello")
    assert {:ok, "hello"} = Server.Database.lookup(database, "first val")
  end

  test "delete val", %{database: database} do
    Server.Database.create(database, "first val", "hello")
    assert Server.Database.lookup(database, "first val") == {:ok, "hello"}

    Server.Database.delete(database, "first val")
    assert :error = Server.Database.lookup(database, "first val")
  end

  test "update val", %{database: database} do
    Server.Database.create(database, "first val", "hello")
    assert Server.Database.lookup(database, "first val") == {:ok, "hello"}

    Server.Database.update(database, "first val", "hello world")
    assert Server.Database.lookup(database, "first val") == {:ok, "hello world"}
  end

  test "search val", %{database: database} do
    JsonLoader.load_to_database(database, "../../orders_dump/dummy_orders.json")

    assert [{"toto", %{"key" => 42}}, {"test", %{"key" => "42"}}] =
             Server.Database.search(database, [{"key", "42"}, {"key", 42}])

    assert [] = Server.Database.search(database, [{"id", "42"}, {"id", 42}])
  end
end
