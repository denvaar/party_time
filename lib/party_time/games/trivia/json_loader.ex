defmodule PartyTime.Games.Trivia.JsonLoader do
  alias PartyTime.Games.Trivia.Game

  def load(data) do
    data
    |> Jason.decode()
    |> build_game(%Game{})
  end

  defp build_game({:ok, json_data}, game) do
    game =
      json_data
      |> Map.get("categories")
      |> Enum.reduce(game, fn category, game ->
        category_name = Map.get(category, "name")

        game = Game.add_category(game, category_name)

        category
        |> Map.get("questions")
        |> Enum.reduce(game, fn question, game ->
          prompt = Map.get(question, "prompt")
          expected_answer = Map.get(question, "expected_answer")
          value = Map.get(question, "value")

          Game.add_question(game, category_name, prompt, expected_answer, value)
        end)
      end)

    {:ok, game}
  end

  defp build_game({:error, _message}, _game) do
    {:error, "Failed to load"}
  end
end
