defmodule Destiny2.Items do
  @moduledoc """
  The Items context.
  """

  import Ecto.Query, warn: false
  alias Destiny2.Repo
  alias Destiny2.Items.Item

  def list_items_by_user(user_id) do
    Repo.all(from i in Item, where: i.user_id == ^user_id, preload: [:character])
  end

  def list_items_by_character(character_id) do
    Repo.all(from i in Item, where: i.character_id == ^character_id)
  end

  def list_vault_items(user_id) do
    Repo.all(from i in Item, where: i.user_id == ^user_id and is_nil(i.character_id))
  end

  def create_or_update_item(attrs) do
    case Repo.get_by(Item, item_instance_id: attrs.item_instance_id, user_id: attrs.user_id) do
      nil ->
        %Item{}
        |> Item.changeset(attrs)
        |> Repo.insert()

      item ->
        item
        |> Item.changeset(attrs)
        |> Repo.update()
    end
  end

  def delete_item(item), do: Repo.delete(item)
end
