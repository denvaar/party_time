defmodule PartyTimeWeb.PageController do
  use PartyTimeWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
