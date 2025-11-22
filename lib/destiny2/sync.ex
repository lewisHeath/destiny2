defmodule Destiny2.Sync do
  @moduledoc """
  Handles synchronization of Destiny 2 profile data (characters, items, etc.)
  from Bungie API to the local database.
  """

  alias Destiny2.BungieAPI
  alias Destiny2.Characters
  alias Destiny2.Items
  alias Destiny2.Repo

  def sync_profile(user) do
    # Components:
    # 200: Characters
    # 201: CharacterInventories (Items in character bags)
    # 205: CharacterEquipment (Items equipped)
    # 102: ProfileInventories (Vault)
    components = [200, 201, 205, 102]

    case BungieAPI.get_profile(user.membership_type, user.membership_id, user.access_token, components) do
      {:ok, data} ->
        Repo.transaction(fn ->
          sync_characters(user, data["characters"]["data"])
          sync_character_equipment(user, data["characterEquipment"]["data"])
          sync_character_inventories(user, data["characterInventories"]["data"])
          sync_vault(user, data["profileInventory"]["data"])
          
        end)
        
        # Fetch definitions in background (or foreground if we want to wait)
        # For now, let's wait so the UI has them on refresh
        all_items = 
            (data["characterEquipment"]["data"] |> Enum.flat_map(fn {_, d} -> d["items"] end)) ++
            (data["characterInventories"]["data"] |> Enum.flat_map(fn {_, d} -> d["items"] end)) ++
            data["profileInventory"]["data"]["items"]
            
        hashes = Enum.map(all_items, &Integer.to_string(&1["itemHash"])) |> Enum.uniq()
        Destiny2.Definitions.ensure_definitions(hashes)

      error -> error
    end
  end

  defp sync_characters(user, characters_data) do
    for {character_id, data} <- characters_data do
      attrs = %{
        character_id: character_id,
        class_type: data["classType"],
        light_level: data["light"],
        emblem_hash: Integer.to_string(data["emblemHash"]),
        emblem_background_path: data["emblemBackgroundPath"],
        race_type: data["raceType"],
        gender_type: data["genderType"],
        date_last_played: parse_date(data["dateLastPlayed"]),
        user_id: user.id
      }

      Characters.create_or_update_character(attrs)
    end
  end

  defp sync_character_equipment(user, equipment_data) do
    for {character_id, data} <- equipment_data do
      items = data["items"]
      sync_items(user, character_id, items, true)
    end
  end

  defp sync_character_inventories(user, inventories_data) do
    for {character_id, data} <- inventories_data do
      items = data["items"]
      sync_items(user, character_id, items, false)
    end
  end

  defp sync_vault(user, vault_data) do
    items = vault_data["items"]
    # Vault items don't belong to a specific character, so character_id is nil
    sync_items(user, nil, items, false)
  end

  defp sync_items(user, character_id, items_data, is_equipped) do
    for item_data <- items_data do
      # Only sync instanced items or items with hashes we care about
      # For now, we sync everything but might need to filter
      
      attrs = %{
        item_instance_id: item_data["itemInstanceId"],
        item_hash: Integer.to_string(item_data["itemHash"]),
        bucket_hash: Integer.to_string(item_data["bucketHash"]),
        is_equipped: is_equipped,
        # We don't have item definitions yet, so name/icon will be missing or need another fetch
        # For now, we'll leave them nil or implement a manifest lookup later
        item_name: "Unknown Item", 
        icon_path: nil,
        power_level: get_instance_power(item_data), # Need instance data for this, usually component 300
        user_id: user.id,
        character_id: get_character_id_db(character_id)
      }

      Items.create_or_update_item(attrs)
    end
  end

  defp get_character_id_db(nil), do: nil
  defp get_character_id_db(bungie_character_id) do
    # We need to look up the internal DB id for the character
    # This is inefficient inside a loop, but for now it works. 
    # Optimization: fetch all char IDs map beforehand.
    case Destiny2.Characters.get_character_by_bungie_id(bungie_character_id) do
      %Destiny2.Characters.Character{id: id} -> id
      nil -> nil
    end
  end
  
  defp get_instance_power(_item_data) do
    # Without ItemInstances component (300), we can't get exact power for every item easily
    # For now, return nil
    nil
  end

  defp parse_date(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _offset} -> datetime
      _ -> DateTime.utc_now()
    end
  end
end
