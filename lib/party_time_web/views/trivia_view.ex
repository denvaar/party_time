defmodule PartyTimeWeb.TriviaView do
  use PartyTimeWeb, :view

  def player_has_control?(game, user_id) do
    game.players
    |> Enum.any?(fn player ->
      player.is_in_control === true && user_id == player.user_id
    end)
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
end
