defmodule PartyTimeWeb.Credentials do
  @moduledoc "Authentication helper functions"

  alias PartyTime.Users.User
  alias Phoenix.LiveView.Socket
  alias Pow.Store.CredentialsCache

  @doc """
  Retrieves the currently-logged-in user from the Pow credentials cache.
  """
  @spec get_user(
          socket :: Socket.t(),
          session :: map(),
          config :: keyword()
        ) :: %User{} | nil

  def get_user(socket, session, config \\ [otp_app: :party_time])

  def get_user(socket, %{"party_time_auth" => signed_token}, config) do
    conn = struct!(Plug.Conn, secret_key_base: socket.endpoint.config(:secret_key_base))
    salt = Atom.to_string(Pow.Plug.Session)

    with {:ok, token} <- Pow.Plug.verify_token(conn, salt, signed_token, config),
         {user, _metadata} <- CredentialsCache.get([backend: Pow.Store.Backend.EtsCache], token) do
      user
    else
      _any -> nil
    end
  end

  def get_user(_, _, _), do: nil
end
