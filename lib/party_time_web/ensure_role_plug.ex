defmodule PartyTimeWeb.EnsureRolePlug do
  @moduledoc """
  This plug ensures that a user has a particular role.

  ## Example

      plug MyAppWeb.EnsureRolePlug, [:user, :admin]

      plug MyAppWeb.EnsureRolePlug, :admin

      plug MyAppWeb.EnsureRolePlug, ~w(user admin)a
  """
  import Plug.Conn, only: [halt: 1]

  alias PartyTimeWeb.Router.Helpers, as: Routes
  alias Phoenix.Controller
  alias Plug.Conn
  alias Pow.Plug

  @doc false
  @spec init(any()) :: any()
  def init(config), do: config

  @doc false
  @spec call(Conn.t(), atom() | binary() | [atom()] | [binary()]) :: Conn.t()
  def call(conn, roles) do
    conn
    |> Plug.current_user()
    |> has_roles?(roles)
    |> maybe_halt(conn)
  end

  defp has_roles?(nil, _roles), do: false

  defp has_roles?(%{roles: user_roles}, roles) when is_list(roles) do
    Enum.all?(roles, fn r ->
      Enum.any?(user_roles, fn ur -> Atom.to_string(r) == ur end)
    end)
  end

  defp has_roles?(%{roles: user_roles}, role) do
    Enum.any?(user_roles, fn ur -> Atom.to_string(role) == ur end)
  end

  defp has_roles?(_user, _roles), do: false

  defp maybe_halt(true, conn), do: conn

  defp maybe_halt(_any, conn) do
    conn
    |> Controller.redirect(to: Routes.page_path(conn, :index))
    |> halt()
  end
end
