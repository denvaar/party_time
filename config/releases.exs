# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :party_time, PartyTime.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

live_view_signing_salt =
  System.get_env("LV_SIGNING_SALT") ||
    raise """
    environment variable LV_SIGNING_SALT is missing.
    """

config :party_time, PartyTimeWeb.Endpoint,
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base,
  live_view: [signing_salt: live_view_signing_salt]

google_client_id =
  System.get_env("GOOGLE_CLIENT_ID") ||
    raise """
    environment variable GOOGLE_CLIENT_ID is missing.
    """

google_client_secret =
  System.get_env("GOOGLE_CLIENT_SECRET") ||
    raise """
    environment variable GOOGLE_CLIENT_SECRET is missing.
    """

config :party_time, :pow_assent,
  providers: [
    google: [
      client_id: google_client_id,
      client_secret: google_client_secret,
      strategy: Assent.Strategy.Google
    ]
  ]

# testing
# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
config :party_time, PartyTimeWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
