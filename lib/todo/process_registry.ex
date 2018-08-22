defmodule Todo.ProcessRegistry do
  def start_link do
    # start a Registry with a name of the module
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def via_tuple(key) do
    {:via, Registry, {__MODULE__, key}}
  end

  # Because our module doesn't use GenServer or SuperVisor, we must define a child_spec
  # in order for it to be Supervised. We'll use Registry's default while overriding i:d and :start
  def child_spec(_) do
    Supervisor.child_spec(
      Registry,
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    )
  end
end
