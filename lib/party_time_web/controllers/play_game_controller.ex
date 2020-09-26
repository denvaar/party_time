defmodule PartyTimeWeb.PlayGameController do
  use PartyTimeWeb, :controller

  alias PartyTimeWeb.GameFinder

  def show(conn, %{"game_code" => game_code}) do
    with {:ok, liveview_module} <- GameFinder.find_liveview_module(game_code) do
      live_render(conn, liveview_module,
        session:
          Map.merge(
            get_session(conn),
            %{"game_code" => game_code}
          )
      )
    else
      {:error, message} ->
        conn
        |> put_view(PartyTimeWeb.PageView)
        |> render(
          :index,
          invalid_game_code: message
        )
    end
  end
end
