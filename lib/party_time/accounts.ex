defmodule PartyTime.Accounts do
  import Ecto.Query, only: [from: 2]

  alias PartyTime.Repo
  alias PartyTime.Users.User

  @type user :: %User{}

  @spec create_admin(map()) :: {:ok, user()} | {:error, Ecto.Changeset.t()}
  def create_admin(params) do
    %User{}
    |> User.changeset(params)
    |> User.changeset_role(%{roles: ["player", "admin"]})
    |> Repo.insert()
  end

  @spec set_admin_role(user()) :: {:ok, user()} | {:error, Ecto.Changeset.t()}
  def set_admin_role(user) do
    user
    |> User.changeset_role(%{roles: ["player", "admin"]})
    |> Repo.update()
  end

  @spec assign_user_role(user(), binary() | atom()) ::
          {:ok, user()} | {:error, Ecto.Changeset.t()}
  def assign_user_role(user, role) when is_atom(role) do
    assign_user_role(user, Atom.to_string(role))
  end

  def assign_user_role(user, role) do
    user
    |> User.changeset_role(%{roles: Enum.uniq([role | user.roles])})
    |> Repo.update()
  end

  @spec remove_user_role(user(), binary() | atom()) ::
          {:ok, user()} | {:error, Ecto.Changeset.t()}
  def remove_user_role(user, role) when is_atom(role) do
    remove_user_role(user, Atom.to_string(role))
  end

  def remove_user_role(user, role) do
    user
    |> User.changeset_role(%{roles: Enum.filter(user.roles, fn ur -> ur != role end)})
    |> Repo.update()
  end

  @spec is_host?(user()) :: boolean()
  def is_host?(%{roles: roles}) do
    Enum.any?(roles, fn r -> r == "host" end)
  end

  def get_users([]), do: []

  def get_users(ids) do
    from(u in User,
      where: u.id in ^ids,
      select: {u.id, u}
    )
    |> Repo.all()
  end
end
