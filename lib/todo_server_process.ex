defmodule TodoServerProcess do

  def start do
    ServerProcess.start(TodoServerProcess)
  end

  def init, do: Todo.List.new()

  def add_entry(pid, %{date: _} = new_entry) do
    ServerProcess.cast(pid, {:add_entry, new_entry})
  end

  def update_entry(pid, id, updater_fun) do
    ServerProcess.cast(pid, {:update_entry, id, updater_fun})
  end

  def update_entry(pid, %{id: _} = entry) do
    ServerProcess.cast(pid, {:update_entry, entry})
  end

  def delete_entry(pid, entry_id) do
    ServerProcess.cast(pid, {:delete_entry, entry_id})
  end

  def entries(pid, date) do
    # Because the server holding our records is in a differnet process, you must communicate using
    # send() and force synchronous processing of the message. You give it your own PID os that it
    # can immediately send a response. This is equivalent to the request,response pattern
    ServerProcess.call(pid, {:entries, date})
  end

  def entry(pid, id) do
    ServerProcess.call(pid, {:entry, id})
  end

  def handle_cast({:add_entry, new_entry}, todo_list) do
    Todo.List.add_entry(todo_list, new_entry)
  end

  def handle_cast({:update_entry, id, updater_fun}, todo_list) do
    Todo.List.update_entry(todo_list, id, updater_fun)
  end

  def handle_cast({:update_entry, entry}, todo_list) do
    Todo.List.update_entry(todo_list, entry)
  end

  def handle_cast({:delete_entry, entry_id}, todo_list) do
    Todo.List.delete_entry(todo_list, entry_id)
  end

  def handle_call({:entries, date}, todo_list) do
    {Todo.List.entries(todo_list, date), todo_list}
  end

  def handle_call({:entry, id}, todo_list) do
    {Todo.List.entry(todo_list, id), todo_list}
  end

end
