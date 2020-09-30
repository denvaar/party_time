defmodule PartyTime.Games.Utils do
  def make_id() do
    3
    |> :crypto.strong_rand_bytes()
    |> Base.encode64()
  end
end
