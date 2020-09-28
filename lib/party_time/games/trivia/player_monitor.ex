defmodule PartyTime.Games.Trivia.PlayerMonitor do
  use GenServer

  def start_link(player, caller_pid) do
    GenServer.start_link(__MODULE__, {player, caller_pid}, name: :"player_#{player.user_id}")
  end

  def dont_kick(pid) do
    send(pid, :dont_kick)
  end

  @impl true
  def init({player, caller_pid}) do
    state = %{player: player, caller_pid: caller_pid, timer: nil}
    {:ok, state, {:continue, :begin_countdown}}
  end

  @impl true
  def handle_continue(:begin_countdown, state) do
    timer =
      Process.send_after(
        self(),
        {:kick_player},
        # one minute
        60_000
      )

    {:noreply, %{state | timer: timer}}
  end

  @impl true
  def handle_info(:dont_kick, %{timer: timer} = state) do
    # not sure if this is required, but oh well
    Process.cancel_timer(timer)

    {:stop, :normal, state}
  end

  def handle_info({:kick_player}, state) do
    send(state.caller_pid, {:remove_player, state.player})
    {:stop, :normal, state}
  end
end
