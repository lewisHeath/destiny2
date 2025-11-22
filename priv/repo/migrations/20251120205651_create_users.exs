defmodule Destiny2.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :membership_id, :string, null: false
      add :membership_type, :integer, null: false
      add :display_name, :string
      add :access_token, :text
      add :refresh_token, :text
      add :token_expires_at, :utc_datetime
      add :refresh_expires_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:membership_id, :membership_type])
  end
end
