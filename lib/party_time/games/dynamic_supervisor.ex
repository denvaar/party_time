defmodule PartyTime.DynamicSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(child) do
    DynamicSupervisor.start_child(__MODULE__, child)
  end

  def terminate_child(child_name) do
    with child_pid <- Process.whereis(child_name) do
      :ok = DynamicSupervisor.terminate_child(__MODULE__, child_pid)
    end
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
