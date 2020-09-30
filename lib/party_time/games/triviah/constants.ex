defmodule Constants do
  values = [game_name: "triviah", update_state_event: "game_state_update"]

  for {key, value} <- values do
    def encode(unquote(key)), do: unquote(value)
    def decode(unquote(value)), do: unquote(key)
  end
end
