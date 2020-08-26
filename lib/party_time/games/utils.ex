defmodule PartyTime.Games.Utils do
  def make_id() do
    3
    |> :crypto.strong_rand_bytes()
    |> Base.encode64()
    |> String.to_atom()
  end
end
