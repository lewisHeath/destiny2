defmodule Destiny2.Repo.Migrations.CreateCharacters do
  use Ecto.Migration

  def change do
    create table(:characters) do
      add :character_id, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :class_type, :integer, null: false
      add :light_level, :integer
      add :emblem_hash, :string
      add :emblem_background_path, :string
      add :race_type, :integer
      add :gender_type, :integer
      add :date_last_played, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:characters, [:character_id, :user_id])
    create index(:characters, [:user_id])
  end
end
