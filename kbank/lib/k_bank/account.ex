defmodule KBank.Account do
  use GenServer

  ## Client API

  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  def lookup(server, accnt_nb) do
    case :ets.lookup(server, accnt_nb) do
      [{^accnt_nb, val}] -> {:ok, val}
      [] -> :error
    end
  end

  def get_all(server) do
    :ets.tab2list(server)
  end

  def is_empty(server) do
    case :ets.first(server) do
      '$end_of_table' -> true
      _ -> false
    end
  end

  def create_account(server, val) do
    {accnt_nb, _val} = GenServer.call(server, {:create, val})
    accnt_nb
  end

  def delete_account(server, accnt_nb) do
    GenServer.call(server, {:delete, accnt_nb})
  end

  def add_money(server, accnt_nb, amount) do
    GenServer.call(server, {:credit, accnt_nb, amount})
  end

  def retrieve_money(server, accnt_nb, amount) do
    GenServer.call(server, {:debit, accnt_nb, amount})
  end

  def update_name(server, accnt_nb, name) do
    GenServer.call(server, {:update, accnt_nb, name})
  end

  ## Server Callbacks

  @impl true
  def init(table_name) do
    accnt_table = :ets.new(table_name, [:named_table, read_concurrency: true])

    case :dets.open_file('Accnt_table.txt') do
      {:error, _} ->
        :dets.open_file(:file_table, [{:file, 'Accnt_table.txt'}, {:ram_file, true}])
        :dets.close(:file_table)
        schedule_work()
        {:ok, accnt_table}

      {:ok, _} ->
        :dets.open_file(:file_table, [{:file, 'Accnt_table.txt'}, {:ram_file, true}])
        :dets.to_ets(:file_table, accnt_table)
        :dets.close(:file_table)
        schedule_work()
        {:ok, accnt_table}
    end
  end

  def change_last_update(accnt_table, accnt_nb) do
    {:ok, val} = lookup(accnt_table, accnt_nb)

    case Map.get(val, :last_update) do
      nil ->
        new_map = val |> Map.put(:last_update, DateTime.utc_now() |> DateTime.to_string())
        :ets.update_element(accnt_table, accnt_nb, {2, new_map})

      _ ->
        new_map = %{val | :last_update => DateTime.utc_now() |> DateTime.to_string()}
        :ets.update_element(accnt_table, accnt_nb, {2, new_map})
    end
  end

  @impl true
  def handle_call({:create, val}, _from, accnt_table) do
    accnt_nb =
      Enum.to_list(1..13)
      |> Enum.map(fn _nb ->
        Enum.random(0..9) |> Integer.to_string()
      end)
      |> Enum.reduce("", fn digit, acc ->
        acc <> digit
      end)

    :ets.insert(accnt_table, {accnt_nb, val})
    change_last_update(accnt_table, accnt_nb)
    {:reply, {accnt_nb, val}, accnt_table}
  end

  @impl true
  def handle_call({:delete, accnt_nb}, _from, accnt_table) do
    case lookup(accnt_table, accnt_nb) do
      {:ok, val} ->
        :ets.delete(accnt_table, accnt_nb)
        {:reply, val, accnt_table}

      :error ->
        {:reply, nil, accnt_table}
    end
  end

  @impl true
  def handle_call({:credit, accnt_nb, amount}, _from, accnt_table) do
    case lookup(accnt_table, accnt_nb) do
      {:ok, val} ->
        new_amt = Map.get(val, :amt) + amount
        new_map = %{val | :amt => new_amt}
        :ets.update_element(accnt_table, accnt_nb, {2, new_map})
        change_last_update(accnt_table, accnt_nb)
        {:reply, {accnt_nb, new_map}, accnt_table}

      :error ->
        {:reply, {accnt_nb, amount}, accnt_table}
    end
  end

  @impl true
  def handle_call({:debit, accnt_nb, amount}, _from, accnt_table) do
    case lookup(accnt_table, accnt_nb) do
      {:ok, val} ->
        new_amt = Map.get(val, :amt) - amount
        new_map = %{val | :amt => new_amt}
        :ets.update_element(accnt_table, accnt_nb, {2, new_map})
        change_last_update(accnt_table, accnt_nb)
        {:reply, {accnt_nb, new_map}, accnt_table}

      :error ->
        {:reply, {accnt_nb, amount}, accnt_table}
    end
  end

  @impl true
  def handle_call({:update, accnt_nb, name}, _from, accnt_table) do
    case lookup(accnt_table, accnt_nb) do
      {:ok, val} ->
        new_map = %{val | :name => name}
        :ets.update_element(accnt_table, accnt_nb, {2, new_map})
        change_last_update(accnt_table, accnt_nb)
        {:reply, {accnt_nb, new_map}, accnt_table}

      :error ->
        {:reply, {accnt_nb, name}, accnt_table}
    end
  end

  @impl true
  def handle_info(:work, accnt_table) do
    save_table(accnt_table)
    schedule_work()
    {:noreply, accnt_table}
  end

  defp schedule_work() do
    Process.send_after(self(), :work, 30_000)
  end

  defp save_table(accnt_table) do
    :dets.open_file(:file_table, [{:file, 'Accnt_table.txt'}])
    :ets.to_dets(accnt_table, :file_table)
    :dets.close(:file_table)
  end
end
