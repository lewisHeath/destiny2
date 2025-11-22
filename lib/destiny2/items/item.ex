defmodule Destiny2.Items.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :item_instance_id, :string
    field :item_hash, :string
    field :bucket_hash, :string
    field :is_equipped, :boolean, default: false
    field :item_name, :string
    field :item_type, :string
    field :tier_type, :string
    field :power_level, :integer
    field :icon_path, :string
    field :json_data, :map

    belongs_to :user, Destiny2.Users.User
    belongs_to :character, Destiny2.Characters.Character

    timestamps(type: :utc_datetime)
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :item_instance_id,
      :item_hash,
      :bucket_hash,
      :is_equipped,
      :item_name,
      :item_type,
      :tier_type,
      :power_level,
      :icon_path,
      :json_data,
      :user_id,
      :character_id
    ])
    |> validate_required([:item_hash, :bucket_hash, :user_id])
  end
end
