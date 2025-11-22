defmodule Destiny2.Characters.Character do
  use Ecto.Schema
  import Ecto.Changeset

  schema "characters" do
    field :character_id, :string
    field :class_type, :integer
    field :light_level, :integer
    field :emblem_hash, :string
    field :emblem_background_path, :string
    field :race_type, :integer
    field :gender_type, :integer
    field :date_last_played, :utc_datetime

    belongs_to :user, Destiny2.Users.User
    has_many :items, Destiny2.Items.Item

    timestamps(type: :utc_datetime)
  end

  def changeset(character, attrs) do
    character
    |> cast(attrs, [
      :character_id,
      :class_type,
      :light_level,
      :emblem_hash,
      :emblem_background_path,
      :race_type,
      :gender_type,
      :date_last_played,
      :user_id
    ])
    |> validate_required([:character_id, :class_type, :user_id])
    |> unique_constraint([:character_id, :user_id])
  end
end
