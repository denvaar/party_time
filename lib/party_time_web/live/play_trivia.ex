defmodule PartyTimeWeb.PlayTriviaLive do
  use PartyTimeWeb, :live_view

  alias PartyTime.Games.Trivia.GameServer

  @game_name "trivia"

  @impl true
  def mount(%{"game_id" => game_id}, session, socket) do
    if connected?(socket) do
      current_user = PartyTimeWeb.Credentials.get_user(socket, session)
      PartyTimeWeb.Endpoint.subscribe("#{@game_name}:updates:#{game_id}")

      connected_user_ids =
        PartyTime.Presence.list_players("#{@game_name}:presences:#{game_id}")
        |> Map.keys()

      is_host = Enum.count(connected_user_ids) == 0

      PartyTime.Presence.track_player(
        "#{@game_name}:presences:#{game_id}",
        current_user.id,
        %{is_host: is_host}
      )

      {:ok,
       assign(socket,
         game: nil,
         game_id: game_id,
         game_status: :lobby,
         is_host: is_host,
         current_user_id: current_user.id
       )}
    else
      {:ok, assign(socket, game: nil, is_host: false, game_status: :lobby)}
    end
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(
      PartyTimeWeb.TriviaView,
      "#{assigns.game_status}.html",
      assigns
    )
  end

  @impl true
  def handle_event("start-game", _params, socket) do
    GameServer.set_game_status(String.to_atom(socket.assigns.game_id), :playing)
    {:noreply, socket}
  end

  def handle_event("pick-question", %{"question_id" => question_id}, socket) do
    GameServer.pick_question(String.to_atom(socket.assigns.game_id), question_id)
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "game_state_update", payload: game}, socket) do
    {:noreply, assign(socket, game_status: game.status, game: game)}
  end
end
