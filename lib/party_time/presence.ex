defmodule PartyTime.Presence do
  use Phoenix.Presence,
    otp_app: :party_time,
    pubsub_server: PartyTime.PubSub

  @spec list_players(String.t()) :: Phoenix.Presence.presences()
  def list_players(topic), do: list(topic)

  @spec track_player(String.t(), pos_integer()) :: :ok | {:error, term()}
  def track_player(topic, player_id, meta \\ %{}) do
    track(self(), topic, player_id, meta)
  end
end
