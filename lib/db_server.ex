defmodule DatabaseServer do
  def start do
    spawn(fn ->
      connection = :rand.uniform(1000) # simulate connection handle
      loop(connection)
    end)
  end

  def run_async(server_pid, query_def), do: send(server_pid, {:run_query, self(), query_def})

  def get_result do
    receive do
      {:query_result, result} -> result
    after
      5000 -> {:error, :timeout}
    end
  end

  defp loop(connection) do
    receive do
      {:run_query, from_pid, query_def} ->
        query_result = run_query(connection, query_def)
        send(from_pid, {:query_result, query_result})
    end
    loop(connection)
  end

  defp run_query(connection, query_def) do
    Process.sleep(1000)
    "Connection #{connection}: #{query_def} result"
  end
end
