defmodule Destiny2Web.ProfileLive do
  use Destiny2Web, :live_view

  alias Destiny2.Characters
  alias Destiny2.Items

  alias Destiny2.Definitions

  on_mount Destiny2Web.Live.EnsureAuth

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      user = socket.assigns.current_user

      # Load characters and items
      characters = Characters.list_characters_by_user(user.id)
      items = Items.list_items_by_user(user.id)
      vault_items = Items.list_vault_items(user.id)

      # Pre-fetch definitions
      all_items = items ++ vault_items
      item_hashes = Enum.map(all_items, & &1.item_hash) |> Enum.uniq()
      definitions = Definitions.get_definitions(item_hashes)
      definitions_map = Map.new(definitions, fn d -> {d.hash, d} end)

      socket =
        socket
        |> assign(:characters, characters)
        |> assign(:items, items)
        |> assign(:vault_items, vault_items)
        |> assign(:definitions, definitions_map)
        |> assign(:loading, false)

      {:ok, socket}
    else
      socket =
        socket
        |> assign(:loading, true)
        |> assign(:characters, [])
        |> assign(:items, [])
        |> assign(:vault_items, [])
        |> assign(:definitions, %{})

      {:ok, socket}
    end
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    user = socket.assigns.current_user

    socket =
      socket
      |> assign(:loading, true)

    # Fetch fresh data from Bungie API
    Task.start(fn ->
      fetch_and_update_profile(user)
      send(self(), :refresh_complete)
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_info(:refresh_complete, socket) do
    user = socket.assigns.current_user

    # Reload data
    characters = Characters.list_characters_by_user(user.id)
    items = Items.list_items_by_user(user.id)
    vault_items = Items.list_vault_items(user.id)

    # Pre-fetch definitions
    all_items = items ++ vault_items
    item_hashes = Enum.map(all_items, & &1.item_hash) |> Enum.uniq()
    definitions = Definitions.get_definitions(item_hashes)
    definitions_map = Map.new(definitions, fn d -> {d.hash, d} end)

    socket =
      socket
      |> assign(:characters, characters)
      |> assign(:items, items)
      |> assign(:vault_items, vault_items)
      |> assign(:definitions, definitions_map)
      |> assign(:loading, false)
      |> put_flash(:info, "Profile updated!")

    {:noreply, socket}
  end

  defp fetch_and_update_profile(user) do
    Destiny2.Sync.sync_profile(user)
  end

  @bucket_hashes %{
    kinetic: "1498876634",
    energy: "2465295065",
    power: "953998645",
    helmet: "3448274439",
    gauntlets: "3551918588",
    chest: "14239492",
    leg: "20886954",
    class: "1585787867",
    ghost: "4023194814",
    vehicle: "2025709351",
    ship: "284967655",
    subclass: "3284755031"
  }
  defp buckets_for_category(:weapons),
    do: [@bucket_hashes.kinetic, @bucket_hashes.energy, @bucket_hashes.power]

  defp buckets_for_category(:armor),
    do: [
      @bucket_hashes.helmet,
      @bucket_hashes.gauntlets,
      @bucket_hashes.chest,
      @bucket_hashes.leg,
      @bucket_hashes.class
    ]

  defp buckets_for_category(:general),
    do: [@bucket_hashes.ghost, @bucket_hashes.vehicle, @bucket_hashes.ship]

  defp equipped_weapon_buckets,
    do: [@bucket_hashes.kinetic, @bucket_hashes.energy, @bucket_hashes.power]

  defp equipped_armor_buckets,
    do: [
      @bucket_hashes.helmet,
      @bucket_hashes.gauntlets,
      @bucket_hashes.chest,
      @bucket_hashes.leg,
      @bucket_hashes.class
    ]

  defp get_items(items, character_id, bucket_hash, definitions_map) do
    Enum.filter(items, fn item ->
      is_correct_char = is_nil(character_id) or item.character_id == character_id

      if is_correct_char do
        if is_nil(character_id) do
          definition = Map.get(definitions_map, item.item_hash)

          if definition do
            def_bucket = definition.json_data["inventory"]["bucketTypeHash"]
            Integer.to_string(def_bucket) == bucket_hash
          else
            item.bucket_hash == bucket_hash
          end
        else
          item.bucket_hash == bucket_hash
        end
      else
        false
      end
    end)
    |> Enum.sort_by(& &1.power_level, :desc)
  end

  defp get_equipped_items(items, character_id, bucket_hash, definitions_map) do
    get_items(items, character_id, bucket_hash, definitions_map)
    |> Enum.filter(& &1.is_equipped)
  end

  defp get_unequipped_items(items, character_id, bucket_hash, definitions_map) do
    get_items(items, character_id, bucket_hash, definitions_map)
    |> Enum.reject(& &1.is_equipped)
  end

  defp class_name(0), do: "Titan"
  defp class_name(1), do: "Hunter"
  defp class_name(2), do: "Warlock"
  defp class_name(_), do: "Unknown"
  attr :item, Destiny2.Items.Item, required: true
  attr :definitions, :map, required: true
  attr :class, :string, default: nil

  defp item_icon(assigns) do
    # Try to find definition
    definition = Map.get(assigns.definitions, assigns.item.item_hash)
    assigns = assign(assigns, :definition, definition)

    ~H"""
    <div
      class={["tooltip", @class]}
      data-tip={item_name(@definition) <> if @item.power_level, do: " (#{ @item.power_level })", else: ""}
    >
      <div class="relative w-full h-full rounded-sm overflow-hidden group cursor-pointer border border-base-300 bg-base-200 hover:border-primary hover:ring-1 hover:ring-primary transition-all duration-200">
        <%= if @definition && @definition.json_data["displayProperties"]["icon"] do %>
          <img
            src={"https://www.bungie.net#{@definition.json_data["displayProperties"]["icon"]}"}
            class="w-full h-full object-cover"
            loading="lazy"
          />
        <% else %>
          <div class="w-full h-full flex items-center justify-center text-[10px] text-center leading-none p-0.5 text-base-content/50">
            ?
          </div>
        <% end %>

        <%= if @item.power_level do %>
          <div class="absolute bottom-0 right-0 bg-black/80 text-[9px] font-mono text-warning px-1 rounded-tl-sm backdrop-blur-[1px]">
            {@item.power_level}
          </div>
        <% end %>

        <%= if @item.is_equipped do %>
          <div class="absolute top-0 left-0 w-0 h-0 border-t-[12px] border-r-[12px] border-t-white border-r-transparent drop-shadow-sm">
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp item_name(nil), do: "Unknown Item"
  defp item_name(definition), do: definition.json_data["displayProperties"]["name"]
end
