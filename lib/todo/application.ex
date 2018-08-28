defmodule Todo.Application do
  use Application

  def start(_, _args) do
    Todo.System.start_link()
  end
end
