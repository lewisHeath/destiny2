defmodule Destiny2.Repo.Migrations.CreateDefinitions do
  use Ecto.Migration

  def change do
    create table(:definitions) do
      add :hash, :string
      add :json_data, :map

      timestamps(type: :utc_datetime)
    end

    create unique_index(:definitions, [:hash])
  end
end
