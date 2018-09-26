defmodule Todo.List do
  defstruct auto_id: 1, entries: %{}
  def new(entries \\ []) do
    Enum.reduce(
      entries,
      %Todo.List{},
      &add_entry(&2, &1) # lambda is called like fn(entry, accumulator)
    )
  end

  # if key of date exists then append title to list, otherwise add new list
  # with key of given date
  def add_entry(%Todo.List{} = todo_list, %{date: _} = entry) do
    entry = Map.put(entry, :id, todo_list.auto_id)

    new_entries = Map.put(
      todo_list.entries,
      todo_list.auto_id,
      entry
    )

    # pipe character lets you update structs or maps if you know key(s) are present
    %Todo.List{ todo_list |
      entries: new_entries,
      auto_id: todo_list.auto_id + 1
    }
  end

  def add_entry(_, _), do: {:error, :invalid_arguments}

  # Delegates by having a lambda just return the entry if it exists and replaces all other keys
  # besides :id
  def update_entry(%Todo.List{} = todo_list, %{id: _} = new_entry) do
    update_entry(todo_list, new_entry.id, fn _ -> new_entry end)
  end

  def update_entry(_, _), do: {:error, :invalid_arguments}

  def update_entry(%Todo.List{} = todo_list, entry_id, updater_fun)
      when is_number(entry_id) and is_function(updater_fun) do
    case Map.fetch(todo_list.entries, entry_id) do
      :error -> todo_list

      # pattern match that updater function returns a map with an unchanged id
      {:ok, old_entry} ->
        old_entry_id = old_entry.id
        new_entry = %{id: ^old_entry_id} = updater_fun.(old_entry)
        new_entries = Map.put(todo_list.entries, new_entry.id, new_entry)
        %Todo.List{todo_list | entries: new_entries}
    end
  end

  def update_entry(_, _, _), do: {:error, :invalid_arguments}

  def delete_entry(%Todo.List{} = todo_list, entry_id) when is_number(entry_id) do
    %Todo.List{ todo_list | entries: Map.delete(todo_list.entries, entry_id) }
  end

  def delete_entry(_, _), do: {:error, :invalid_arguments}

  def all_entries(%Todo.List{} = todo_list) do
    todo_list.entries
    |> Enum.map(fn {_, entry} -> entry end)
  end

  def all_entries(_), do: {:error, :invalid_arguments}

  def entries(%Todo.List{} = todo_list, date) do
    todo_list.entries |>
    # Stream.filter turns maps into tuple {key, value}
    Stream.filter(fn {_, entry} -> entry.date == date end) |>
    Enum.map(fn {_, entry} -> entry end)
  end

  def entries(_, _), do: {:error, :invalid_arguments}

  def entry(%Todo.List{} = todo_list, id) do
    Map.get(todo_list.entries, id)
  end
end

defmodule Todo.List.CsvImporter do
  def import(file) do
    file |>
    read_lines |>
    create_entries |>
    Todo.List.new()
  end

  defp read_lines(file) do
    file |>
    File.stream!() |>
    Stream.map(&String.replace(&1, "\n", ""))
  end

  defp create_entries(lines) do
    lines |>
    Stream.map(&extract_fields/1) |>
    Stream.map(&create_entry/1)
  end

  defp extract_fields(line) do
    line |>
    String.split(",") |>
    convert_date
  end

  defp convert_date([date_string, title]) do
    {parse_date(date_string), title}
  end

  defp parse_date(date_string) do
    [year, month, day] =
      date_string |>
      String.split("/") |>
      Enum.map(&String.to_integer/1)

    {:ok, date} = Date.new(year, month, day)
    date
  end

  defp create_entry({date, title}) do
    %{date: date, title: title}
  end
end
