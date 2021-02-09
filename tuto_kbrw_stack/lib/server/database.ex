defmodule Server.Database do
  use GenServer

  ## Client API

  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  # CRUD operations

  def lookup(server, key) do
    case :ets.lookup(server, key) do
      [{^key, val}] -> {:ok, val}
      [] -> :error
    end
  end

  def create(server, key, val) do
    GenServer.call(server, {:create, key, val})
  end

  def delete(server, key) do
    GenServer.call(server, {:delete, key})
  end

  def update(server, key, new_val) do
    GenServer.call(server, {:update, key, new_val})
  end

  def search(server, criteria) do
    GenServer.call(server, {:search, criteria})
  end

  ## Server Callbacks

  @impl true
  def init(table_name) do
    my_table = :ets.new(table_name, [:named_table, read_concurrency: true])
    {:ok, my_table}
  end

  @impl true
  def handle_call({:create, key, val}, _from, my_table) do
    case lookup(my_table, key) do
      {:ok, _val} ->
        {:reply, :error, my_table}

      :error ->
        :ets.insert(my_table, {key, val})
        {:reply, val, my_table}
    end
  end

  @impl true
  def handle_call({:delete, key}, _from, my_table) do
    case lookup(my_table, key) do
      {:ok, val} ->
        :ets.delete(my_table, key)
        {:reply, val, my_table}

      :error ->
        {:reply, nil, my_table}
    end
  end

  @impl true
  def handle_call({:update, key, new_val}, _from, my_table) do
    case lookup(my_table, key) do
      {:ok, _val} ->
        :ets.delete(my_table, key)
        :ets.insert(my_table, {key, new_val})
        {:reply, new_val, my_table}

      :error ->
        {:reply, new_val, my_table}
    end
  end

  @impl true
  def handle_call({:search, criteria}, _from, my_table) do
    my_list = :ets.tab2list(my_table)

    response =
      criteria
      |> Enum.reduce([], fn criter, acc ->
        result =
          my_list
          |> Enum.filter(fn {_key, map} ->
            Map.get(map, elem(criter, 0)) == elem(criter, 1)
          end)

        result ++ acc
      end)

    {:reply, response, my_table}
  end
end
