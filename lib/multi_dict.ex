defmodule MultiDict do
  def new(), do: %{}

  # if key of key exists then append value to list, otherwise add new list with key of given key
  def add(dict, key, value) do
    Map.update(dict, key, [value], &[value | &1])
  end

  def get(dict, key), do: Map.get(dict, key, [])
end
