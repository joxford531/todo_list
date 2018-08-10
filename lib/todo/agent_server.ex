defmodule Todo.AgentServer do
  use Agent, restart: :temporary

  def start_link(list_name) do
    Agent.start_link(
      fn ->
        IO.puts("Starting Todo Server - #{list_name}")
        {list_name, Todo.Database.get(list_name) || Todo.List.new()}
      end,
      name: via_tuple(list_name)
    )
  end

  def add_entry(todo_server, %{date: _} = new_entry) do
    # {name, todo_list} is the shape of state returned by start_link
    Agent.cast(todo_server, fn {name, todo_list} ->
      new_list = Todo.List.add_entry(todo_list, new_entry)
      Todo.Database.store(name, new_list)
      {name, new_list}
    end)
  end

  def update_entry(todo_server, id, updater_fun) do
    Agent.cast(todo_server, fn {name, todo_list} ->
      new_list = Todo.List.update_entry(todo_list, id, updater_fun)
      Todo.Database.store(name, new_list)
      {name, new_list}
    end)
  end

  def update_entry(todo_server, %{id: _} = entry) do
    Agent.cast(todo_server, fn {name, todo_list} ->
      new_list = Todo.List.update_entry(todo_list, entry)
      Todo.Database.store(name, new_list)
      {name, new_list}
    end)
  end

  def delete_entry(todo_server, entry_id) do
    Agent.cast(todo_server, fn {name, todo_list} ->
      new_list = Todo.List.delete_entry(todo_list, entry_id)
      Todo.Database.store(name, new_list)
      {name, new_list}
    end)
  end

  def entries(todo_server, date) do
    Agent.get(
      todo_server,
      fn {_name, todo_list} -> Todo.List.entries(todo_list, date)
    end)
  end

  def entry(todo_server, id) do
    Agent.get(
      todo_server,
      fn {_name, todo_list} -> Todo.List.entry(todo_list, id)
    end)
  end

  defp via_tuple(list_name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, list_name})
  end
end
