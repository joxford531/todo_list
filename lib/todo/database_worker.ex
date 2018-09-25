defmodule Todo.DatabaseWorker do
  use GenServer

  def start_link(db_folder) do
    GenServer.start_link(__MODULE__, db_folder)
  end

  def store(pid, key, data) do
    GenServer.call(pid, {:store, key, data})
  end

  def get(pid, key) do
    # call Registry to get the pid of the worker with a specific key
    GenServer.call(pid, {:get, key})
  end

  @impl true
  def init(db_folder) do
    {:ok, db_folder}
  end

  @impl true
  def handle_call({:store, key, data}, _, db_folder) do
    results =
      file_name(db_folder, key)
      |> File.write!(:erlang.term_to_binary(data))

    {:reply, results, db_folder}
  end

  @impl true
  def handle_call({:get, key}, _, db_folder) do
    data =
      case File.read(file_name(db_folder, key)) do
        {:ok, contents} ->
          :erlang.binary_to_term(contents)
        {:error, :enoent} -> nil # only handle no such fille error otherwise let it crash and have the Supervisor recover
      end

    {:reply, data, db_folder}
  end

  defp file_name(db_folder, key) do
    Path.join(db_folder, to_string(key))
  end
end
