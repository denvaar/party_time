defmodule PartyTimeWeb.PageController do
  use PartyTimeWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def create(conn, %{"game_code" => game_code}) do
    if Process.whereis(String.to_atom(game_code)) do
      path =
        Routes.play_trivia_path(
          PartyTimeWeb.Endpoint,
          :index,
          game_code
        )

      redirect(conn, to: path)
    else
      conn
      |> render(:index, invalid_game_code: "Nope, no game with that code")
    end
  end

  def new_game(conn, _params) do
    render(conn, "new_game.html")
  end

  def create_game(conn, %{"game_code" => game_code, "upload" => upload}) do
    {:ok, data} = File.read(upload.path)

    with {:ok, game} <- PartyTime.Games.Trivia.JsonLoader.load(data) do
      {:ok, _pid} = start_new_game(game_code, game)

      path =
        Routes.play_trivia_path(
          PartyTimeWeb.Endpoint,
          :index,
          game_code
        )

      redirect(conn, to: path)
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
