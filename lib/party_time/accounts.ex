defmodule PartyTime.Accounts do
  import Ecto.Query, only: [from: 2]

  alias PartyTime.Repo
  alias PartyTime.Users.User

  def get_users([]), do: []

  def get_users(ids) do
    from(u in User,
      where: u.id in ^ids,
      select: {u.id, u}
    )
    |> Repo.all()

    # ids
    # |> Enum.map(fn i -> {i, %{id: i, given_name: "Denver", family_name: "Smith"}} end)
  end
end
