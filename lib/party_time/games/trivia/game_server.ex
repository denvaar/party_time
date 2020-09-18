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

  def pick_question(game_id, question_id, category_name) do
    GenServer.cast(game_id, {:pick_question, question_id, category_name})
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
  def init(game_id) do
    state =
      %{
        game_id: game_id,
        game: %Game{
          categories: [
            %PartyTime.Games.Trivia.Category{
              name: "NASA Space Voyages Gone Wrong",
              questions: [
                %PartyTime.Games.Trivia.Question{
                  prompt: "asdfasdf",
                  expected_answer: "asdfasdf",
                  value: 200,
                  id: :"1"
                },
                %PartyTime.Games.Trivia.Question{
                  prompt: "aasdfasdfsdfasdf",
                  expected_answer: "asdsdfiasdfasfasdf",
                  value: 400,
                  id: :"2"
                }
              ]
            },
            %PartyTime.Games.Trivia.Category{
              name: "asdfas asdf asdf asdf asdf",
              questions: [
                %PartyTime.Games.Trivia.Question{
                  prompt: "asdfa asdf asdfsdf",
                  expected_answer: "asdfasdf",
                  value: 200,
                  id: :asdfasfd1
                },
                %PartyTime.Games.Trivia.Question{
                  prompt: "aasasd asdf asdf asdf dfasdfsdfasdf",
                  expected_answer: "asdsdfiasdfaasdfasdf afsd asdf sfasdf",
                  value: 400,
                  id: :"2wwwewe"
                }
              ]
            },
            %PartyTime.Games.Trivia.Category{
              name: "asfd asaaa aa  a a a sdfa",
              questions: [
                %PartyTime.Games.Trivia.Question{
                  prompt: "asdfa asdf asdfsdf",
                  expected_answer: "asdfasdf",
                  value: 200,
                  id: :asdfasfdsssd1
                },
                %PartyTime.Games.Trivia.Question{
                  prompt: "aasasd asdf asdf asdf dfasdfsdfasdf",
                  expected_answer: "asdsdfiasdfaasdfasdf afsd asdf sfasdf",
                  value: 400,
                  id: :"2wwwewasdfasdfe"
                }
              ]
            },
            %PartyTime.Games.Trivia.Category{
              name: "World Geography",
              questions: [
                %PartyTime.Games.Trivia.Question{
                  prompt: "asdfasdasdf asdf asdf f",
                  expected_answer: "asdfasdf",
                  value: 200,
                  id: :"12"
                },
                %PartyTime.Games.Trivia.Question{
                  prompt: "aasdfasdfsdfaasdf asdf asdf asdfsdf",
                  expected_answer: "asdsdfiasdfasfasdf",
                  value: 400,
                  id: :"22"
                }
              ]
            }
          ]
        },
        timer_ref: nil
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

  def handle_cast({:pick_question, question_id, category_name}, state) do
    question = Game.pick_question(state.game, String.to_atom(question_id))

    PartyTimeWeb.Endpoint.broadcast!(
      game_updates_topic(state.game_id),
      "game_meta_update",
      %{current_question: question, selected_category: category_name}
    )

    {:noreply, %{state | current_question: question, selected_category: category_name}}
  end

  def handle_cast({:judge_answer, "correct"}, state) do
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

  def handle_cast({:judge_answer, "incorrect"}, state) do
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

    {:noreply, %{state | game: game} |> Map.merge(meta_state)}
  end

  def handle_cast({:submit_answer, player_answer}, state) do
    if state.timer_ref do
      Process.cancel_timer(state.timer_ref)
    end

    PartyTimeWeb.Endpoint.broadcast!(
      game_meta_topic(state.game_id),
      "game_meta_update",
      %{player_answer: player_answer, buzz_in_seconds_remaining: nil}
    )

    {:noreply,
     %{state | timer_ref: nil, buzz_in_seconds_remaining: nil, player_answer: player_answer}}
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

  def handle_info({:tick, 0}, state) do
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

    meta_state = %{
      current_question: current_question,
      buzz_in_seconds_remaining: nil,
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

    {:noreply, %{state | timer_ref: nil, game: game} |> Map.merge(meta_state)}
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
      Game.remove_player(game, String.to_integer(id))
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
      question_answer_history: []
    }
  end
end
