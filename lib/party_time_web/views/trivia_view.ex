defmodule PartyTimeWeb.TriviaView do
  use PartyTimeWeb, :view

  def player_has_control?(game, user_id) do
    game.players
    |> Enum.any?(fn player ->
      player.is_in_control === true && user_id == player.user_id
    end)
  end

  def controlling_player(game) do
    game.players
    |> Enum.find(fn player -> player.is_in_control === true end)
  end

  def player(players, id) do
    players
    |> Enum.find(fn player ->
      player.user_id == id
    end)
  end

  def players_sorted_by_score(players) do
    players
    |> Enum.sort_by(fn player ->
      player.score * -1
    end)
  end

  def answer_status_css_class(nil, nil), do: "unanswered"
  def answer_status_css_class(_buzzed_in_user_id, true), do: "correct-answer"
  def answer_status_css_class(_buzzed_in_user_id, false), do: "incorrect-answer"
  def answer_status_css_class(_buzzed_in_user_id, nil), do: "pending-answer"

  def category_questions(categories, category_name) do
    categories
    |> Enum.find(fn category -> category.name == category_name end)
    |> questions_in_category()
  end

  defp questions_in_category(nil), do: []
  defp questions_in_category(category), do: category.questions

  def render("scripts.html", _assigns) do
    href = Routes.static_path(PartyTimeWeb.Endpoint, "/css/trivia.css")
    src = Routes.static_path(PartyTimeWeb.Endpoint, "/js/trivia.js")

    ~E(<link rel="stylesheet" href="<%= href %>"/><script type="text/javascript" src="<%= src %>"></script>)
  end
end
