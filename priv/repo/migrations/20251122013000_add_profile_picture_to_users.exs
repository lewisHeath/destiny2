defmodule Destiny2.Repo.Migrations.AddProfilePictureToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :profile_picture_path, :string
    end
  end
end
