defmodule PartyTimeWeb.RedirectHome do
  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> Phoenix.Controller.redirect(to: "/")
    |> Plug.Conn.halt()
  end
end
