defmodule MyCalendarServer do
  def start do
    spawn(fn -> loop(MyCalendar.new()) end)
  end  

  defp loop(task_list) do
    new_task_list =
      receive do
        message -> process_message(task_list, message)
      end
  end

  def add_entry(my_calendar_server, new_entry) do
    send(my_calendar_server, {:add_entry, new_entry})
  end

  def entries(my_calendar_server, date) do
    send(my_calendar_server, {:entries, self(), date})

    receive do
      {:task_entries, entries} -> entries
    after
      5000 -> {:error, :timeout}
    end
  end

  defp process_message(task_list, {:add_entry, new_entry}) do
    MyCalendar.add_entry(task_list, new_entry)
  end
  defp process_message(task_list, {:entries, caller, date}) do
    send(caller, {:task_entries}, MyCalendar.entries(task_list, date))
    task_list
  end
end

defmodule MyCalendar do

  defimpl Collectable, for: MyCalendar do
    def into(original) do
      {original, &into_callback/2}
    end

    defp into_callback(task_list, {:cont, entry}) do
      MyCalendar.add_entry(task_list, entry)
    end

    defp into_callback(task_list, :done), do: task_list 
    defp into_callback(task_list, :halt), do: :ok
  end
  defstruct next_id: 1, entries: %{}

  def new(entries \\ []) do
    Enum.reduce(
      entries, 
      %MyCalendar{},
      fn entry, acc ->
        add_entry(acc, entry)
      end
    ) 
  end
  
  def add_entry(task_list, entry) do
    entry = Map.put(entry, :id, task_list.next_id)

    new_entries = Map.put(
      task_list.entries,
      task_list.next_id,
      entry
    )

    %MyCalendar{task_list | entries: new_entries, next_id: task_list.next_id + 1}
  end

  def entries(task_list, date) do
    task_list.entries 
    |> Map.values()
    |> Enum.filter(&(&1.date == date))
  end

  def get_today(task_list) do
    task_list.entries 
    |> Map.values()
    |> Enum.filter(&(&1.date == Date.utc_today()))
  end

  def update_entry(task_list, id, updater_func) do
    case Map.fetch(task_list.entries, id) do
      :error -> task_list
      {:ok, old_entry} ->
        new_entry = updater_func.(old_entry)
        new_entries = Map.put(task_list.entries, new_entry.id, new_entry)
        %MyCalendar{task_list | entries: new_entries}
    end
  end

  def delete_entry(task_list, id), do: Map.delete(task_list.entries, id)
end

defmodule MyCalendar.CsvImporter do
  defp read_file(path), do: File.stream!(path)
  
  def init(path) do
    stream = read_file(path) |>
      Stream.map(fn item -> 
          String.trim_trailing(item) |>
          String.split(",")
        end
      )

    Enum.map(stream, fn [date | title]-> 
      %{date: date |> Date.from_iso8601() |> elem(1), title: title}
    end) |> 
    MyCalendar.new()
  end
end
