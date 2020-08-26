defmodule PartyTimeWeb.TriviaLive do
  use PartyTimeWeb, :live_view

  alias PartyTime.Games.Trivia.GameServer

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, game: nil, game_status: :landing)}
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
  def handle_event("join-game", %{"join_game" => %{"game_code" => game_code}}, socket) do
    path =
      PartyTimeWeb.Router.Helpers.play_trivia_path(
        PartyTimeWeb.Endpoint,
        :index,
        game_code
      )

    {:noreply, push_redirect(socket, to: path)}
  end

  def handle_event("create-game", _params, socket) do
    game_id = PartyTime.Games.Utils.make_id()

    with {:ok, _pid} <- new_game(game_id) do
      {
        :noreply,
        assign(socket,
          game_id: game_id,
          game: GameServer.get_state(game_id),
          game_status: :setup,
          adding_question_category: nil
        )
      }
    end
  end

  def handle_event(
        "create-category",
        %{"category_name" => category_name},
        socket
      ) do
    game = GameServer.add_category(socket.assigns.game_id, category_name)

    {:noreply, assign(socket, game: game)}
  end

  def handle_event("add-question", %{"category_name" => category_name}, socket) do
    {:noreply, assign(socket, adding_question_category: category_name)}
  end

  def handle_event(
        "create-question",
        %{
          "category_name" => category_name,
          "prompt" => prompt,
          "expected_answer" => expected_answer,
          "value" => value
        },
        socket
      ) do
    game =
      GameServer.add_question(
        socket.assigns.game_id,
        category_name,
        prompt,
        expected_answer,
        value
      )

    {:noreply, assign(socket, adding_question_category: nil, game: game)}
  end

  def handle_event("next", _params, socket) do
    path =
      PartyTimeWeb.Router.Helpers.play_trivia_path(
        PartyTimeWeb.Endpoint,
        :index,
        socket.assigns.game_id
      )

    {:noreply, push_redirect(socket, to: path)}
  end

  defp new_game(game_id) do
    {GameServer, game_id}
    |> PartyTime.DynamicSupervisor.start_child()
  end
end
