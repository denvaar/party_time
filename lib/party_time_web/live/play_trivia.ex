defmodule PartyTimeWeb.PlayTriviaLive do
  use PartyTimeWeb, :live_view

  alias PartyTime.Games.Trivia.GameServer

  @game_name "trivia"

  def find_game(game_id) do
    pid =
      game_id
      |> String.to_atom()
      |> Process.whereis()

    if pid do
      GameServer.get_state(pid)
    else
      %{}
    end
  end

  def check_if_started(%{status: :lobby} = game, {game_id, socket, session}) do
    current_user = PartyTimeWeb.Credentials.get_user(socket, session)
    # Updates about the game state changes
    PartyTimeWeb.Endpoint.subscribe("#{@game_name}:updates:#{game_id}")
    # Updates not neccessarily about the game state itself...idk how to explain
    PartyTimeWeb.Endpoint.subscribe("#{@game_name}:meta:#{game_id}")

    connected_user_ids =
      PartyTime.Presence.list_players("#{@game_name}:presences:#{game_id}")
      |> Map.keys()

    is_host =
      Enum.count(connected_user_ids) == 0 &&
        Enum.any?(current_user.roles, fn role -> role == "host" end)

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
       current_user_id: current_user.id,
       selected_category: nil,
       current_question: nil
     )}
  end

  def check_if_started(%{status: :playing}, {_game_id, socket, _session}) do
    {:ok, assign(socket, game_status: :already_started)}
  end

  def check_if_started(_game, {game_id, socket, _session}) do
    {:ok,
     redirect(socket, to: Routes.page_path(PartyTimeWeb.Endpoint, :index, game_code: game_id))}
  end

  @impl true
  def mount(%{"game_id" => game_id}, session, socket) do
    if connected?(socket) do
      game_id
      |> find_game()
      |> check_if_started({game_id, socket, session})
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
    socket.assigns.game_id
    |> String.to_atom()
    |> GameServer.set_game_status(:playing)

    {:noreply, socket}
  end

  def handle_event("buzz-in", _params, socket) do
    socket.assigns.game_id
    |> String.to_atom()
    |> GameServer.buzz_in(socket.assigns.current_user_id)

    {:noreply, socket}
  end

  def handle_event("judge-answer", %{"value" => verdict}, socket) do
    socket.assigns.game_id
    |> String.to_atom()
    |> GameServer.judge_answer(verdict)

    {:noreply, socket}
  end

  def handle_event(
        "typing-answer",
        %{"player_answer" => %{"answer" => player_answer}},
        socket
      ) do
    GameServer.type_answer(String.to_atom(socket.assigns.game_id), player_answer)
    {:noreply, socket}
  end

  def handle_event("submit-answer", %{"player_answer" => %{"answer" => player_answer}}, socket) do
    GameServer.submit_answer(String.to_atom(socket.assigns.game_id), player_answer)
    {:noreply, socket}
  end

  def handle_event("select-category", %{"selected_category" => selected_category}, socket) do
    GameServer.view_category(String.to_atom(socket.assigns.game_id), selected_category)
    {:noreply, socket}
  end

  def handle_event(
        "select-question",
        %{"selected_question" => id, "selected_category" => category_name},
        socket
      ) do
    socket.assigns.game_id
    |> String.to_atom()
    |> GameServer.pick_question(id, category_name)

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "game_state_update", payload: game}, socket) do
    {:noreply, assign(socket, game_status: game.status, game: game)}
  end

  def handle_info(%{event: "game_meta_update", payload: meta}, socket) do
    {:noreply, assign(socket, Map.to_list(meta))}
  end
end
