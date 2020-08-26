defmodule PartyTime.Games.Trivia.GameServer do
  use GenServer, restart: :temporary

  alias PartyTime.Games.Trivia.Game
  alias PartyTime.Accounts

  # client

  def start_link(game_id) do
    GenServer.start_link(__MODULE__, game_id, name: game_id)
  end

  def get_state(game_id) do
    GenServer.call(game_id, :get_state)
  end

  def add_category(game_id, category_name) do
    GenServer.call(game_id, {:add_category, category_name})
  end

  def add_question(game_id, category_name, prompt, expected_answer, value) do
    GenServer.call(game_id, {:add_question, category_name, prompt, expected_answer, value})
  end

  def set_game_status(game_id, status) do
    GenServer.cast(game_id, {:set_status, status})
  end

  def pick_question(game_id, question_id) do
    GenServer.cast(game_id, {:pick_question, question_id})
  end

  def end_game(game_id) do
    send(game_id, :game_over)
  end

  # server

  @impl true
  def init(game_id) do
    state = %{
      game_id: game_id,
      game: %Game{}
    }

    {:ok, state, {:continue, :subscribe_presence}}
  end

  @impl true
  def handle_continue(:subscribe_presence, state) do
    state.game_id
    |> presence_topic()
    |> PartyTimeWeb.Endpoint.subscribe()

    {:noreply, state}
  end

  @impl true
  def handle_cast({:set_status, status}, state) do
    game = Game.set_status(state.game, status)

    game =
      if status == :playing do
        Game.give_control(game, List.first(game.players).user_id)
      else
        game
      end

    PartyTimeWeb.Endpoint.broadcast!(
      game_updates_topic(state.game_id),
      "game_state_update",
      game
    )

    {:noreply, %{state | game: game}}
  end

  def handle_cast({:pick_question, question_id}, state) do
    game = Game.pick_question(state.game, String.to_atom(question_id))

    PartyTimeWeb.Endpoint.broadcast!(
      game_updates_topic(state.game_id),
      "game_state_update",
      game
    )

    {:noreply, %{state | game: game}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state.game, state}
  end

  def handle_call({:add_category, category_name}, _from, state) do
    game = Game.add_category(state.game, category_name)
    new_state = %{state | game: game}

    {:reply, game, new_state}
  end

  def handle_call({:add_question, category_name, prompt, expected_answer, value}, _from, state) do
    game =
      Game.add_question(
        state.game,
        category_name,
        prompt,
        expected_answer,
        value
      )

    new_state = %{state | game: game}

    {:reply, game, new_state}
  end

  @impl true
  def handle_info(:game_over, state) do
    {:stop, :normal, state}
  end

  def handle_info(%{event: "presence_diff", payload: %{joins: joins, leaves: leaves}}, state) do
    game =
      state.game
      |> handle_joins(joins)
      |> handle_leaves(leaves)

    PartyTimeWeb.Endpoint.broadcast!(
      game_updates_topic(state.game_id),
      "game_state_update",
      game
    )

    new_state = %{state | game: game}

    no_connections? =
      PartyTime.Presence.list_players(presence_topic(state.game_id))
      |> Map.keys()
      |> Enum.empty?()

    if no_connections? do
      {:stop, :normal, new_state}
    else
      {:noreply, new_state}
    end
  end

  defp handle_joins(game, joins) do
    joins
    |> Map.to_list()
    |> Enum.filter(fn {_, %{metas: [meta]}} ->
      meta.is_host == false
    end)
    |> Enum.map(fn {id, _} -> String.to_integer(id) end)
    |> Accounts.get_users()
    |> Enum.reduce(game, fn {_id, user}, game ->
      Game.add_player(
        game,
        {user.id, "#{user.given_name} #{String.first(user.family_name)}. (#{user.email})"}
      )
    end)
  end

  defp handle_leaves(game, leaves) do
    leaves
    |> Map.keys()
    |> Enum.reduce(game, fn id, game ->
      Game.remove_player(game, String.to_integer(id))
    end)
  end

  defp game_updates_topic(game_id), do: "trivia:updates:#{game_id}"

  defp presence_topic(game_id), do: "trivia:presences:#{game_id}"
end
