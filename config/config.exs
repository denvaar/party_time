# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :party_time,
  ecto_repos: [PartyTime.Repo]

config :party_time, :pow,
  user: PartyTime.Users.User,
  repo: PartyTime.Repo,
  web_module: PartyTimeWeb

# Configures the endpoint
config :party_time, PartyTimeWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: PartyTimeWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: PartyTime.PubSub

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
