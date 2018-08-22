defmodule Todo.Database do
  @pool_size 3
  @db_folder "./persist" # equivalent to a constant property

  def start_link() do # called by Supervisor in Todo.System
    IO.puts("Starting database server")

    File.mkdir_p!(@db_folder)
    children = Enum.map(1..@pool_size, &worker_spec/1)
    Supervisor.start_link(children, strategy: :one_for_one) # supervise db pool workers
  end

  defp worker_spec(worker_id) do
    # since there is a start_link() method in DBWorker, Supervisor will know how to start each worker
    default_worker_spec = {Todo.DatabaseWorker, {@db_folder, worker_id}}

    # lets you set unique id for worker, otherwise id would always id would always be Todo.Database (module name)
    # returns a map of the shape %{id: worker_id, start: {Todo.DatabaseWorker, :start_link, [{@dbfolder, worker_id}] }}
    Supervisor.child_spec(default_worker_spec, id: worker_id)
  end

  # must define child_spec when you want this to be a supervised process and you don't use
  #Genserver
  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  def store(key, data) do
    key
    |> choose_worker()
    |> Todo.DatabaseWorker.store(key, data)
  end

  def get(key) do
    key
    |> choose_worker()
    |> Todo.DatabaseWorker.get(key)
  end

  defp choose_worker(key) do
    :erlang.phash2(key, @pool_size) + 1
  end
end
