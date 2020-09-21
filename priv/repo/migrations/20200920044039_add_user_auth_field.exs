defmodule PartyTime.Repo.Migrations.AddUserAuthField do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :roles, {:array, :string}, default: ["player"]
    end
  end
end
