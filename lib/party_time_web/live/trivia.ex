defmodule PartyTimeWeb.TriviaLive do
  use PartyTimeWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(
      PartyTimeWeb.TriviaView,
      "lobby.html",
      assigns
    )
  end
end
