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
end
