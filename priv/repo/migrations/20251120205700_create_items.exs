defmodule Destiny2.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :item_instance_id, :string
      add :item_hash, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :character_id, references(:characters, on_delete: :delete_all)
      add :bucket_hash, :string, null: false
      add :is_equipped, :boolean, default: false
      add :item_name, :string
      add :item_type, :string
      add :tier_type, :string
      add :power_level, :integer
      add :icon_path, :string
      add :json_data, :map

      timestamps(type: :utc_datetime)
    end

    create index(:items, [:user_id])
    create index(:items, [:character_id])
    create index(:items, [:bucket_hash])
    create index(:items, [:item_hash])
  end
end
