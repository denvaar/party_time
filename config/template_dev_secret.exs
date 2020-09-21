use Mix.Config

config :party_time, PartyTimeWeb.Endpoint,
  secret_key_base: "FILL_ME_IN",
  live_view: [signing_salt: "FILL_ME_IN"]

config :party_time, :pow_assent,
  providers: [
    google: [
      client_id: "FILL_ME_IN",
      client_secret: "FILL_ME_IN",
      strategy: Assent.Strategy.Google
    ]
  ]
