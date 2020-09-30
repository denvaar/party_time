defmodule PartyTimeWeb.GameFinder do
  @game_not_found_message "Nope, no game with that code"
  @default_view PartyTimeWeb.PageView

  def game_pid(game_code) do
    with [{pid, _}] <- Registry.lookup(:game_registry, game_code) do
      pid
    else
      _ -> nil
    end
  end

  def find_liveview_module(game_code) do
    game_code
    |> game_pid()
    |> get_game_name()
    |> lookup_liveview_module()
  end

  def find_view_module(["play", game_code]) do
    game_code
    |> game_pid()
    |> get_game_name()
    |> lookup_view_module()
  end

  def find_view_module(_), do: @default_view

  # ---

  defp get_game_name(nil), do: {:error, @game_not_found_message}

  defp get_game_name(game_pid) do
    game_pid
    |> :sys.get_state()
    |> Map.get(:game_name)
  end

  defp lookup_liveview_module(game_name) do
    [modules: modules] = Application.fetch_env!(:party_time, :games)

    with {_name, lv_module, _v_module} <-
           Enum.find(modules, fn {name, _lv_module, _v_module} -> name == game_name end) do
      {:ok, lv_module}
    else
      _ ->
        {:error, @game_not_found_message}
    end
  end

  defp lookup_view_module({:error, _}) do
    @default_view
  end

  defp lookup_view_module(game_name) do
    [modules: modules] = Application.fetch_env!(:party_time, :games)

    with {_name, _lv_module, v_module} <-
           Enum.find(modules, fn {name, _lv_module, _v_module} -> name == game_name end) do
      v_module
    else
      _ -> @default_view
    end
  end
end
