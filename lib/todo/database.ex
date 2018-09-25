defmodule Todo.Database do
  @pool_size 3
  @db_folder "./persist" <> "/#{Atom.to_string(Node.self) |> String.split("@") |> Enum.take(1)}"

  # Poolboy will call Todo.DatabaseWorker.start_link with the argument of @db_folder
  def child_spec(_) do
    File.mkdir_p!(@db_folder)

    :poolboy.child_spec(
      __MODULE__,
      [
        name: {:local, __MODULE__},
        worker_module: Todo.DatabaseWorker,
        size: @pool_size
      ],
      [@db_folder]
    )
  end

  def store(key, data) do
    {_results, bad_nodes} =
      :rpc.multicall(
        __MODULE__,
        :store_local,
        [key, data],
        :timer.seconds(5)
      )

      Enum.each(bad_nodes, &IO.puts("Store failed on node #{&1}"))
      :ok
  end

  def store_local(key, data) do
    :poolboy.transaction(
      __MODULE__,
      fn worker_pid -> # poolboy calls this lambda with one of the three worker's pids
        Todo.DatabaseWorker.store(worker_pid, key, data)
      end
    )
  end

  def get(key) do
    :poolboy.transaction(
      __MODULE__,
      fn worker_pid ->
        Todo.DatabaseWorker.get(worker_pid, key)
      end
    )
  end
end
