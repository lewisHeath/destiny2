defmodule Destiny2.Characters do
  @moduledoc """
  The Characters context.
  """

  import Ecto.Query, warn: false
  alias Destiny2.Repo
  alias Destiny2.Characters.Character

  def list_characters_by_user(user_id) do
    Repo.all(from c in Character, where: c.user_id == ^user_id, preload: [:items])
  end

  def get_character(id), do: Repo.get(Character, id) |> Repo.preload([:user, :items])

  def get_character_by_bungie_id(bungie_id) do
    Repo.get_by(Character, character_id: bungie_id)
  end

  def create_or_update_character(attrs) do
    case Repo.get_by(Character, character_id: attrs.character_id, user_id: attrs.user_id) do
      nil ->
        %Character{}
        |> Character.changeset(attrs)
        |> Repo.insert()

      character ->
        character
        |> Character.changeset(attrs)
        |> Repo.update()
    end
  end

  def delete_character(character), do: Repo.delete(character)
end
