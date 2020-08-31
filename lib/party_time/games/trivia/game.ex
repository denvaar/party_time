defmodule PartyTime.Games.Trivia.Game do
  @moduledoc """
  Defines the state for Trivia, a game that allows players to
  try to answer questions that are presented to them with the
  goal being to have the highest score at the end.
  """

  alias PartyTime.Games.Trivia.{Player, Category, Question}

  @type status ::
          :lobby
          | :choose_question
          | :answer_question
          | :playing
          | :score_answer
          | :game_over
  @type t :: %__MODULE__{
          status: status(),
          players: list(Player.t()),
          categories: list(Category.t())
        }

  defstruct status: :lobby, players: [], categories: []

  @doc """
  Add player to a Trivia game.
  """
  @spec add_player(t(), {pos_integer(), String.t()}) :: t()
  def add_player(state, {user_id, display_name}) do
    %{
      state
      | players: [%Player{user_id: user_id, display_name: display_name} | state.players]
    }
  end

  @doc """
  Remove a player to a Trivia game.
  """
  @spec remove_player(t(), pos_integer()) :: t()
  def remove_player(state, user_id) do
    %{
      state
      | players: Enum.filter(state.players, fn player -> player.user_id != user_id end)
    }
  end

  @doc """
  Add a new category
  """
  @spec add_category(t(), String.t()) :: t()
  def add_category(state, category_name) do
    %{
      state
      | categories: [
          %Category{name: category_name} | state.categories
        ]
    }
  end

  @doc """
  Add a new question under the specified category
  """
  @spec add_question(t(), String.t(), String.t(), String.t(), non_neg_integer()) :: t()
  def add_question(state, category_name, prompt, expected_answer, value) do
    case find_category_by_name(state.categories, category_name) do
      nil ->
        state

      category_index ->
        %{
          state
          | categories:
              List.update_at(state.categories, category_index, fn category ->
                Category.add_question(
                  category,
                  prompt,
                  expected_answer,
                  value
                )
              end)
        }
    end
  end

  @doc """
  Return a question for the given question id
  """
  @spec pick_question(t(), atom()) :: Question.t()
  def pick_question(state, question_id) do
    get_current_question(state, question_id)
  end

  def give_control(state, user_id) do
    %{
      state
      | players:
          Enum.map(state.players, fn player ->
            %{player | is_in_control: user_id == player.user_id}
          end)
    }
  end

  @doc """
  Mark the specified question as unavailable
  """
  @spec mark_question_unavailable(t(), atom()) :: t()
  def mark_question_unavailable(state, question_id) do
    category_index =
      state.categories
      |> find_category_of_question(question_id)

    updated_categories =
      state.categories
      |> List.update_at(category_index, fn category ->
        question_index =
          category.questions
          |> Enum.find_index(fn question ->
            question.id == question_id
          end)

        updated_questions =
          category.questions
          |> List.update_at(question_index, fn question ->
            %{question | is_available: false}
          end)

        %{category | questions: updated_questions}
      end)

    %{state | categories: updated_categories}
    |> set_game_status()
  end

  @doc """
  Make it so that a player cannot answer the question
  again, and deduct points from their score
  """
  @spec incorrect_answer(t(), pos_integer(), non_neg_integer()) :: t()
  def incorrect_answer(state, player_id, value) do
    players =
      update_player(state.players, player_id, fn player ->
        %{player | score: player.score - value, able_to_answer: false}
      end)

    state
    |> set_game_status()
    |> Map.put(:players, players)
  end

  @doc """
  A few things happen when a player is awarded a correct answer

  - They get points
  - They gain control to pick the next question
  - The question answered becomes unavailable
  """
  @spec correct_answer(t(), pos_integer(), non_neg_integer(), atom()) :: t()
  def correct_answer(state, player_id, value, question_id) do
    players =
      Enum.map(state.players, fn player ->
        %{player | is_in_control: false}
      end)
      |> update_player(player_id, fn player ->
        %{player | is_in_control: true, score: player.score + value}
      end)

    %{state | players: players}
    |> mark_question_unavailable(question_id)
    |> set_game_status()
  end

  def set_status(state, status) do
    %{state | status: status}
  end

  defp find_category_by_name(categories, name) do
    categories
    |> Enum.find_index(fn category ->
      category.name == name
    end)
  end

  defp update_player(players, player_id, update_callback) do
    player_index =
      players
      |> Enum.find_index(fn player ->
        player.user_id == player_id
      end)

    List.update_at(players, player_index, update_callback)
  end

  defp find_category_of_question(categories, question_id) do
    categories
    |> Enum.find_index(fn category ->
      Enum.any?(category.questions, fn question ->
        question.id == question_id
      end)
    end)
  end

  defp get_current_question(state, question_id) do
    state.categories
    |> Enum.reduce(
      [],
      fn category, questions ->
        category.questions ++ questions
      end
    )
    |> Enum.find(fn question ->
      question.id == question_id
    end)
  end

  defp set_game_status(state) do
    state
    |> check_game_over()
  end

  defp check_game_over(state) do
    no_questions_available? =
      state.categories
      |> Enum.all?(fn category ->
        Enum.all?(category.questions, fn question ->
          question.is_available == false
        end)
      end)

    if no_questions_available?, do: %{state | status: :game_over}, else: state
  end
end
