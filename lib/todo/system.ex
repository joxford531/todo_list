defmodule Todo.System do
  def start_link do
    Supervisor.start_link(
      [
        {
          Cluster.Supervisor,
          [Application.get_env(:libcluster, :topologies), [name: __MODULE__.ClusterSupervisor]]
        },
        Todo.Database,
        Todo.Cache,
        Todo.Web
      ],
      strategy: :one_for_one
    )
  end
end
