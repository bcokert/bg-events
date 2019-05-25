defmodule Event.Persister do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @spec get(String.t()) :: %Event{} | :none
  def get(name) do
    GenServer.call(Event.Persister, {:get, name})
  end

  @spec get_all() :: [%Event{}]
  def get_all do
    GenServer.call(Event.Persister, {:get_all})
  end

  @spec create(%Event{}) :: %Event{}
  def create(event) do
    GenServer.call(Event.Persister, {:create, event})
    event
  end

  def init(:ok) do
    {:ok, table} = :dets.open_file(Application.get_env(:born_gosu_gaming, :db_file), [type: :set])
    {:ok, table}
  end

  defp first_or_none([first | _]), do: first
  defp first_or_none([]), do: :none

  def handle_call({:get, name}, _from, table) do
    result_list = :dets.lookup(table, name)
    {:reply, first_or_none(result_list), table}
  end

  def handle_call({:get_all}, _from, table) do
    results = :dets.traverse(table, fn obj -> {:continue, elem(obj, 1)} end)
    {:reply, results, table}
  end

  def handle_call({:create, event}, _from, table) do
    :ok = :dets.insert(table, {event.name, event})
    {:reply, event, table}
  end
end