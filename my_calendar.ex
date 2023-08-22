defmodule MyCalendar do
  defstruct next_id: 1, entries: %{}

  def new(), do: %MyCalendar{}
  
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
