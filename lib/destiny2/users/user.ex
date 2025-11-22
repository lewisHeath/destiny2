defmodule Destiny2.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :membership_id, :string
    field :membership_type, :integer
    field :display_name, :string
    field :access_token, :string
    field :refresh_token, :string
    field :token_expires_at, :utc_datetime
    field :refresh_expires_at, :utc_datetime

    has_many :characters, Destiny2.Characters.Character
    has_many :items, Destiny2.Items.Item

    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :membership_id,
      :membership_type,
      :display_name,
      :access_token,
      :refresh_token,
      :token_expires_at,
      :refresh_expires_at
    ])
    |> validate_required([:membership_id, :membership_type])
    |> unique_constraint([:membership_id, :membership_type])
  end
end
