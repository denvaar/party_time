defmodule PartyTimeWeb.TriviaView do
  use PartyTimeWeb, :view

  def current_player_in_control?(game, current_user_id) do
    game.players
    |> Enum.any?(fn player ->
      player.is_in_control === true && current_user_id == player.user_id
    end)
  end
end
