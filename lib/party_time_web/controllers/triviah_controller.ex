defmodule PartyTimeWeb.TriviahController do
  use PartyTimeWeb, :controller

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"game_code" => game_code, "upload" => upload}) do
    {:ok, data} = File.read(upload.path)

    with {:ok, game} <- PartyTime.Games.Trivia.JsonLoader.load(data) do
      {:ok, _pid} = start_new_game(game_code, game)

      redirect(conn,
        to:
          Routes.play_game_path(
            conn,
            :show,
            game_code
          )
      )
    else
      {:error, message} ->
        {:error, message}
    end
  end

  defp start_new_game(game_code, game) do
    {PartyTime.Games.Triviah.GameState, {game_code, game}}
    |> PartyTime.DynamicSupervisor.start_child()
  end
end
