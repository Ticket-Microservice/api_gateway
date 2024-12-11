defmodule Counter do
  use GenServer

  # Client API
  def start_link(initial_value) do
    GenServer.start_link(__MODULE__, initial_value, name: __MODULE__)
  end

  def increment() do
    GenServer.cast(__MODULE__, :increment)
  end

  def get_count() do
    GenServer.call(__MODULE__, :get_count)
  end

  # Server Callbacks
  def init(initial_value) do
    {:ok, initial_value}
  end

  def handle_cast(:increment, state) do
    {:noreply, state + 1}
  end

  def handle_call(:get_count, _from, state) do
    {:reply, state, state}
  end
end

# Usage
{:ok, _pid} = Counter.start_link(0)
Counter.increment()
IO.puts("Count: #{Counter.get_count()}")
