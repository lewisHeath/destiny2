defmodule Destiny2.Definitions.Definition do
  use Ecto.Schema
  import Ecto.Changeset

  schema "definitions" do
    field :hash, :string
    field :json_data, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(definition, attrs) do
    definition
    |> cast(attrs, [:hash, :json_data])
    |> validate_required([:hash])
    |> unique_constraint(:hash)
  end
end
