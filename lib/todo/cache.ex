defmodule Todo.Cache do

  def start_link() do
    IO.puts("Starting to-do cache")

    DynamicSupervisor.start_link(name: __MODULE__, strategy: :one_for_one)
  end

  # must define child_spec when you want this to be a supervised process and you don't use
  # Genserver
  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  def server_process(todo_list_name) do
    existing_process(todo_list_name) || new_process(todo_list_name)
  end

  defp existing_process(todo_list_name) do
    Todo.Server.whereis(todo_list_name) # if not registered will return nil which is treated as falsy
  end

  defp new_process(todo_list_name) do
    case DynamicSupervisor.start_child(
      __MODULE__,
    {Todo.Server, todo_list_name}
    ) do
      {:ok, pid} -> pid
      {:error, {:already_started, pid}} -> pid
    end
  end
end

defmodule Benchmark do
  def measure(func) do
    func
    |> :timer.tc
    |> elem(0)
  end
end
