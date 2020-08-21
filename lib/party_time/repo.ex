defmodule PartyTime.Repo do
  use Ecto.Repo,
    otp_app: :party_time,
    adapter: Ecto.Adapters.Postgres
end
