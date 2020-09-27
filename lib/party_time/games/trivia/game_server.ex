defmodule PartyTime.Games.Trivia.GameServer do
  use GenServer, restart: :temporary

  alias PartyTime.Games.Trivia.Game
  alias PartyTime.Accounts

  # client

  def start_link({game_id, game}) do
    GenServer.start_link(__MODULE__, {game_id, game}, name: game_id)
  end

  def get_state(game_id) do
    GenServer.call(game_id, :get_state)
  end

  def set_game_status(game_id, status) do
    GenServer.cast(game_id, {:set_status, status})
  end

  def pick_question(game_id, question_id, category_name) do
    GenServer.cast(game_id, {:pick_question, question_id, category_name})
  end

  def view_category(game_id, category_name) do
    GenServer.cast(game_id, {:view_category, category_name})
  end

  def buzz_in(game_id, user_id) do
    GenServer.cast(game_id, {:buzz_in, user_id})
  end

  def submit_answer(game_id, player_answer) do
    GenServer.cast(game_id, {:submit_answer, player_answer})
  end

  def type_answer(game_id, player_answer) do
    GenServer.cast(game_id, {:type_answer, player_answer})
  end

  def judge_answer(game_id, verdict) do
    GenServer.cast(game_id, {:judge_answer, verdict})
  end

  def end_game(game_id) do
    send(game_id, :game_over)
  end

  # server

  @impl true
  def init({game_id, game}) do
    state =
      %{
        game_name: "trivia",
        game_id: game_id,
        game: game,
        timer_ref: nil,
        question_timeout_timer_ref: nil
      }
      |> Map.merge(initial_meta())

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

  def handle_cast({:view_category, category_name}, state) do
    PartyTimeWeb.Endpoint.broadcast!(
      game_updates_topic(state.game_id),
      "game_meta_update",
      %{selected_category: category_name}
    )

    {:noreply, %{state | selected_category: category_name}}
  end

  def handle_cast({:pick_question, question_id, category_name}, state) do
    question = Game.pick_question(state.game, String.to_atom(question_id))
    game = Game.make_everyone_able_to_answer(state.game)

    PartyTimeWeb.Endpoint.broadcast!(
      game_updates_topic(state.game_id),
      "game_state_update",
      game
    )

    PartyTimeWeb.Endpoint.broadcast!(
      game_updates_topic(state.game_id),
      "game_meta_update",
      %{current_question: question, selected_category: category_name}
    )

    question_timeout_timer_ref =
      Process.send_after(
        self(),
        {:question_timeout},
        10_000
      )

    {:noreply,
     %{
       state
       | game: game,
         question_timeout_timer_ref: question_timeout_timer_ref,
         current_question: question,
         selected_category: category_name
     }}
  end

  def handle_cast({:judge_answer, "correct"}, state) do
    Process.send_after(
      self(),
      {:judge_answer, "correct"},
      5_000
    )

    # set answer status as correct
    meta_state = %{answer_status: :correct}

    PartyTimeWeb.Endpoint.broadcast!(
      game_meta_topic(state.game_id),
      "game_meta_update",
      meta_state
    )

    {:noreply, Map.merge(state, meta_state)}
  end

  def handle_cast({:judge_answer, "incorrect"}, state) do
    Process.send_after(
      self(),
      {:judge_answer, "incorrect"},
      5_000
    )

    # set answer status as incorrect
    meta_state = %{answer_status: :incorrect}

    PartyTimeWeb.Endpoint.broadcast!(
      game_meta_topic(state.game_id),
      "game_meta_update",
      meta_state
    )

    {:noreply, Map.merge(state, meta_state)}
  end

  def handle_cast({:submit_answer, player_answer}, state) do
    if state.timer_ref do
      Process.cancel_timer(state.timer_ref)
    end

    PartyTimeWeb.Endpoint.broadcast!(
      game_meta_topic(state.game_id),
      "game_meta_update",
      %{player_answer: player_answer, buzz_in_seconds_remaining: nil, answer_status: :pending}
    )

    {:noreply,
     %{
       state
       | timer_ref: nil,
         buzz_in_seconds_remaining: nil,
         player_answer: player_answer,
         answer_status: :pending
     }}
  end

  def handle_cast({:type_answer, player_answer}, state) do
    PartyTimeWeb.Endpoint.broadcast!(
      game_meta_topic(state.game_id),
      "game_meta_update",
      %{player_answer: player_answer}
    )

    {:noreply, %{state | player_answer: player_answer}}
  end

  def handle_cast({:buzz_in, user_id}, state) do
    if state.question_timeout_timer_ref do
      Process.cancel_timer(state.question_timeout_timer_ref)
    end

    PartyTimeWeb.Endpoint.broadcast!(
      game_meta_topic(state.game_id),
      "game_meta_update",
      %{buzzed_in_user_id: user_id}
    )

    timer_ref =
      Process.send_after(
        self(),
        {:tick, 15},
        10
      )

    {:noreply, %{state | timer_ref: timer_ref, buzzed_in_user_id: user_id}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state.game, state}
  end

  @impl true
  def handle_info(:game_over, state) do
    {:stop, :normal, state}
  end

  def handle_info({:tick, 0}, state) do
    # A players buzzed in but didn't answer in time

    game =
      Game.incorrect_answer(
        state.game,
        state.buzzed_in_user_id,
        state.current_question.value
      )

    all_answered? =
      game.players
      |> Enum.all?(fn player -> player.able_to_answer == false end)

    game =
      if all_answered? do
        Game.mark_question_unavailable(game, state.current_question.id)
      else
        game
      end

    PartyTimeWeb.Endpoint.broadcast!(
      game_updates_topic(state.game_id),
      "game_state_update",
      game
    )

    current_question = if all_answered?, do: nil, else: state.current_question

    question_timeout_timer_ref =
      if all_answered? do
        nil
      else
        Process.send_after(
          self(),
          {:question_timeout},
          7_000
        )
      end

    meta_state = %{
      current_question: current_question,
      buzz_in_seconds_remaining: nil,
      player_answer: nil,
      buzzed_in_user_id: nil,
      question_answer_history: [
        {state.buzzed_in_user_id, "--", false} | state.question_answer_history
      ]
    }

    PartyTimeWeb.Endpoint.broadcast!(
      game_meta_topic(state.game_id),
      "game_meta_update",
      meta_state
    )

    {:noreply,
     %{state | question_timeout_timer_ref: question_timeout_timer_ref, timer_ref: nil, game: game}
     |> Map.merge(meta_state)}
  end

  def handle_info({:tick, seconds_remaining}, state) do
    PartyTimeWeb.Endpoint.broadcast!(
      game_meta_topic(state.game_id),
      "game_meta_update",
      %{buzz_in_seconds_remaining: seconds_remaining}
    )

    timer_ref =
      Process.send_after(
        self(),
        {:tick, seconds_remaining - 1},
        1_000
      )

    {:noreply, %{state | timer_ref: timer_ref, buzz_in_seconds_remaining: seconds_remaining}}
  end

  def handle_info({:question_timeout}, state) do
    game = Game.mark_question_unavailable(state.game, state.current_question.id)

    PartyTimeWeb.Endpoint.broadcast!(
      game_updates_topic(state.game_id),
      "game_state_update",
      game
    )

    PartyTimeWeb.Endpoint.broadcast!(
      game_meta_topic(state.game_id),
      "game_meta_update",
      %{current_question: nil}
    )

    {:noreply, %{state | current_question: nil, question_timeout_timer_ref: nil, game: game}}
  end

  def handle_info({:judge_answer, "correct"}, state) do
    game =
      Game.correct_answer(
        state.game,
        state.buzzed_in_user_id,
        state.current_question.value,
        state.current_question.id
      )

    PartyTimeWeb.Endpoint.broadcast!(
      game_updates_topic(state.game_id),
      "game_state_update",
      game
    )

    meta_state = %{
      answer_status: nil,
      current_question: nil,
      buzz_in_seconds_remaining: nil,
      buzzed_in_user_id: nil,
      player_answer: nil,
      question_answer_history: [
        {state.buzzed_in_user_id, state.player_answer, true} | state.question_answer_history
      ]
    }

    PartyTimeWeb.Endpoint.broadcast!(
      game_meta_topic(state.game_id),
      "game_meta_update",
      meta_state
    )

    {:noreply, %{state | game: game} |> Map.merge(meta_state)}
  end

  def handle_info({:judge_answer, "incorrect"}, state) do
    game =
      Game.incorrect_answer(
        state.game,
        state.buzzed_in_user_id,
        state.current_question.value
      )

    all_answered? =
      game.players
      |> Enum.all?(fn player -> player.able_to_answer == false end)

    game =
      if all_answered? do
        Game.mark_question_unavailable(game, state.current_question.id)
      else
        game
      end

    current_question = if all_answered?, do: nil, else: state.current_question

    meta_state = %{
      answer_status: nil,
      current_question: current_question,
      buzz_in_seconds_remaining: nil,
      buzzed_in_user_id: nil,
      player_answer: nil,
      question_answer_history: [
        {state.buzzed_in_user_id, state.player_answer, false} | state.question_answer_history
      ]
    }

    PartyTimeWeb.Endpoint.broadcast!(
      game_updates_topic(state.game_id),
      "game_state_update",
      game
    )

    PartyTimeWeb.Endpoint.broadcast!(
      game_meta_topic(state.game_id),
      "game_meta_update",
      meta_state
    )

    question_timeout_timer_ref =
      if all_answered? do
        nil
      else
        Process.send_after(
          self(),
          {:question_timeout},
          7_000
        )
      end

    {:noreply,
     %{state | game: game, question_timeout_timer_ref: question_timeout_timer_ref}
     |> Map.merge(meta_state)}
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

    PartyTimeWeb.Endpoint.broadcast!(
      game_meta_topic(state.game_id),
      "game_meta_update",
      initial_meta()
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
        {user.id, "#{user.given_name} #{String.first(user.family_name)}.", user.picture}
      )
    end)
  end

  defp handle_leaves(game, leaves) do
    leaves
    |> Map.keys()
    |> Enum.reduce(game, fn id, game ->
      game = Game.remove_player(game, String.to_integer(id))

      if length(game.players) > 0 && Enum.all?(game.players, fn p -> !p.is_in_control end) do
        Game.give_control(game, List.first(game.players).user_id)
      else
        game
      end
    end)
  end

  defp game_updates_topic(game_id), do: "trivia:updates:#{game_id}"

  defp game_meta_topic(game_id), do: "trivia:meta:#{game_id}"

  defp presence_topic(game_id), do: "trivia:presences:#{game_id}"

  defp initial_meta() do
    %{
      current_question: nil,
      selected_category: nil,
      player_answer: nil,
      buzz_in_seconds_remaining: nil,
      buzzed_in_user_id: nil,
      question_answer_history: [],
      answer_status: nil
    }
  end
end
