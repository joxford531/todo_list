defmodule Todo.Server do
  use GenServer, restart: :temporary

  def start_link(list_name) do
    IO.puts("Starting Todo Server - #{list_name}")
    GenServer.start_link(Todo.Server, list_name, name: via_tuple(list_name))
  end

  @impl true
  def init(list_name) do
    send(self(), :real_init) # call separate init process as it may be long running
    {:ok, { list_name, nil } }
  end

  def add_entry(todo_server, %{date: _} = new_entry) do
    GenServer.cast(todo_server, {:add_entry, new_entry})
  end

  def update_entry(todo_server, id, updater_fun) do
    GenServer.cast(todo_server, {:update_entry, id, updater_fun})
  end

  def update_entry(todo_server, %{id: _} = entry) do
    GenServer.cast(todo_server, {:update_entry, entry})
  end

  def delete_entry(todo_server, entry_id) do
    GenServer.cast(todo_server, {:delete_entry, entry_id})
  end

  def entries(todo_server, date) do
    GenServer.call(todo_server, {:entries, date})
  end

  def entry(todo_server, id) do
    GenServer.call(todo_server, {:entry, id})
  end

  defp via_tuple(list_name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, list_name})
  end

  @impl true
  def handle_cast({:add_entry, new_entry}, {list_name, todo_list}) do
    new_list = Todo.List.add_entry(todo_list, new_entry)
    Todo.Database.store(list_name, new_list)
    {:noreply, {list_name, new_list} }
  end

  @impl true
  def handle_cast({:update_entry, id, updater_fun}, {list_name, todo_list}) do
    new_list = Todo.List.update_entry(todo_list, id, updater_fun)
    Todo.Database.store(list_name, new_list)
    {:noreply, {list_name, new_list} }
  end

  @impl true
  def handle_cast({:update_entry, entry}, {list_name, todo_list}) do
    new_list = Todo.List.update_entry(todo_list, entry)
    Todo.Database.store(list_name, new_list)
    {:noreply, {list_name, new_list} }
  end

  @impl true
  def handle_cast({:delete_entry, entry_id}, {list_name, todo_list}) do
    new_list = Todo.List.delete_entry(todo_list, entry_id)
    Todo.Database.store(list_name, new_list)
    {:noreply, {list_name, new_list} }
  end

  @impl true
  def handle_call({:entries, date}, _, {list_name, todo_list}) do
    {:reply, Todo.List.entries(todo_list, date), {list_name, todo_list} }
  end

  @impl true
  def handle_call({:entry, id}, _, {list_name, todo_list}) do
    {:reply, Todo.List.entry(todo_list, id), {list_name, todo_list} }
  end

  @impl true
  def handle_info(:real_init, { list_name, _}) do
    {:noreply, {list_name, Todo.Database.get(list_name) || Todo.List.new() } }
  end

  @impl true
  def handle_info(unknown_message, state) do
    super(unknown_message, state)
  end

end
