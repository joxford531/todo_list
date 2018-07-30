defmodule ServerProcess do
  # callback_module is an atom that represents a module that is a concrete implementation
  # start returns a PID
  def start(callback_module) do
    spawn(fn ->
      initial_state = callback_module.init()
      loop(callback_module, initial_state)
    end)
  end
  # lets you issue requests to the server process
  def call(server_pid, request) do
    send(server_pid, {:call, request, self()})

    receive do
      {:response, response} -> response
    after
      5000 -> {:error, :timeout}
    end
  end
  # async request
  def cast(server_pid, request) do
    send(server_pid, {:cast, request})
  end

  defp loop(callback_module, current_state) do
    receive do
      {:call, request, caller} ->
        {response, new_state} =
          callback_module.handle_call(request, current_state) # invoke concrete module callback

        send(caller, {:response, response})
        loop(callback_module, new_state)

      {:cast, request} ->
        new_state =
          callback_module.handle_cast(request, current_state)

        loop(callback_module, new_state)
    end
  end
end
