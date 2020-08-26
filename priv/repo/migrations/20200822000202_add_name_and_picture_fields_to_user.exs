defmodule PartyTime.Repo.Migrations.AddNameAndPictureFieldsToUser do
  use Ecto.Migration

  def change do
    alter table("users") do
      add :given_name, :string
      add :family_name, :string
      add :name, :string
      add :picture, :string
    end
  end
end
