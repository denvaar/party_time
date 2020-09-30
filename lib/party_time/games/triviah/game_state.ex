defmodule PartyTime.Games.Triviah.GameState do
  use GenServer, restart: :transient

  alias PartyTime.Games.Trivia.Game

  @type state :: %{
          optional(:game) => Game.t()
        }

  @game_name "triviah"
  @update_state_event "game_state_update"
  @timeout 600_000

  # client

  def start_link({game_code, game}) do
    name = via_tuple(game_code)
    GenServer.start_link(__MODULE__, {game_code, game}, name: name)
  end

  @spec set_state(term(), state()) :: :ok
  def set_state(game_code, update) do
    GenServer.cast(via_tuple(game_code), {:set_state, update})
  end

  @spec get_state(term()) :: state()
  def get_state(game_code) do
    GenServer.call(via_tuple(game_code), :get_state)
  end

  # server

  @impl true
  def init({game_code, game}) do
    state = %{
      game_name: @game_name,
      game_code: game_code,
      game: game
    }

    {:ok, state, @timeout}
  end

  @impl true
  def handle_cast({:set_state, update}, state) do
    new_state =
      state
      |> Map.merge(update)

    {:noreply, new_state, {:continue, :broadcast_updates}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, public_state(state), state, @timeout}
  end

  @impl true
  def handle_continue(:broadcast_updates, state) do
    PartyTimeWeb.Endpoint.broadcast!(
      game_updates_topic(state.game_code),
      @update_state_event,
      public_state(state)
    )

    {:noreply, state, @timeout}
  end

  @impl true
  def handle_info(:timeout, game) do
    {:stop, :normal, game}
  end

  # - - - -
  #  - - - -

  defp via_tuple(game_code) do
    {:via, Registry, {:game_registry, game_code}}
  end

  defp public_state(state) do
    Map.take(state, [:game])
  end

  defp game_updates_topic(game_code), do: "#{@game_name}:updates:#{game_code}"
end
