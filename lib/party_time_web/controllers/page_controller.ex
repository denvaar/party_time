defmodule PartyTimeWeb.PageController do
  use PartyTimeWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def create(conn, %{"game_code" => game_code}) do
    redirect(conn,
      to:
        Routes.play_game_path(
          conn,
          :show,
          game_code
        )
    )
  end

  def new_game(conn, _params) do
    render(conn, "new_game.html")
  end

  def create_game(conn, %{"game_code" => game_code, "upload" => upload}) do
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

  defp start_new_game(game_id, game) do
    {PartyTime.Games.Trivia.GameServer, {String.to_atom(game_id), game}}
    |> PartyTime.DynamicSupervisor.start_child()
  end
end
