defmodule PartyTimeWeb.TriviahLive do
  use PartyTimeWeb, :live_view

  alias PartyTime.Games.Triviah.{GameState}
  alias PartyTime.Games.Trivia.{Game}
  alias PartyTime.{DynamicSupervisor, LiveMonitor, Presence}
  alias PartyTimeWeb.{Credentials, Endpoint}

  @game_name "triviah"

  @impl true
  def mount(_params, session, socket) do
    game_code = Map.get(session, "game_code")

    if connected?(socket) do
      current_user = Credentials.get_user(socket, session)

      Endpoint.subscribe(game_updates_topic(game_code))

      LiveMonitor.monitor(
        self(),
        __MODULE__,
        %{id: current_user.id, game_code: game_code}
      )

      game =
        game_code
        |> GameState.get_state()
        |> Map.get(:game)
        |> Game.add_player({current_user.id, current_user.given_name, current_user.picture})

      GameState.set_state(game_code, %{game: game})

      {:ok, assign(socket, game: game, game_code: game_code, game_status: :lobby)}
    else
      {:ok, assign(socket, game: nil, game_code: game_code, game_status: :lobby)}
    end
  end

  def unmount(_reason, %{id: user_id, game_code: game_code} = meta) do
    game_code = game_code

    game =
      game_code
      |> GameState.get_state()
      |> Map.get(:game)
      |> Game.remove_player(user_id)

    if length(game.players) == 0 do
      DynamicSupervisor.terminate_child(game_code)
    else
      GameState.set_state(game_code, %{game: game})
    end

    :ok
  end

  @impl true
  def render(assigns) do
    Phoenix.View.render(
      PartyTimeWeb.TriviahView,
      "#{assigns.game_status}.html",
      assigns
    )
  end

  @impl true
  def handle_event("start-game", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: "game_state_update", payload: state}, socket) do
    {:noreply, assign(socket, Map.to_list(state))}
  end

  # -  -  -  -  -
  #  -  -  -  -  -

  defp game_updates_topic(game_code), do: "#{@game_name}:updates:#{game_code}"
end
