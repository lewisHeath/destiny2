defmodule Destiny2Web.ProfileLive do
  use Destiny2Web, :live_view

  alias Destiny2.Characters
  alias Destiny2.Items
  alias Destiny2.BungieAPI

  on_mount Destiny2Web.Live.EnsureAuth

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      user = socket.assigns.current_user

      # Load characters and items
      characters = Characters.list_characters_by_user(user.id)
      items = Items.list_items_by_user(user.id)
      vault_items = Items.list_vault_items(user.id)

      socket =
        socket
        |> assign(:characters, characters)
        |> assign(:items, items)
        |> assign(:vault_items, vault_items)
        |> assign(:loading, false)

      {:ok, socket}
    else
      socket =
        socket
        |> assign(:loading, true)
        |> assign(:characters, [])
        |> assign(:items, [])
        |> assign(:vault_items, [])
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

    socket =
      socket
      |> assign(:characters, characters)
      |> assign(:items, items)
      |> assign(:vault_items, vault_items)
      |> assign(:loading, false)
      |> put_flash(:info, "Profile updated!")

    {:noreply, socket}
  end

  defp fetch_and_update_profile(user) do
    Destiny2.Sync.sync_profile(user)
  end

  alias Destiny2.Definitions

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

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={%{}} current_user={@current_user}>
      <div class="min-h-screen bg-base-300 text-base-content font-sans">
        <!-- Top Bar -->
        <div class="navbar bg-base-100 shadow-md sticky top-0 z-50 px-4">
          <div class="flex-1">
            <a class="btn btn-ghost text-xl font-bold tracking-tighter">DESTINY 2 MANAGER</a>
          </div>
          <div class="flex-none gap-2">
            <button phx-click="refresh" class="btn btn-ghost btn-circle" disabled={@loading}>
              <%= if @loading do %>
                <span class="loading loading-spinner loading-sm"></span>
              <% else %>
                <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" /></svg>
              <% end %>
            </button>
            <div class="dropdown dropdown-end">
              <div tabindex="0" role="button" class="btn btn-ghost btn-circle avatar">
                <div class="w-10 rounded-full">
                  <img alt="User" src="https://www.bungie.net/img/theme/bungienet/icons/default_avatar.jpg" />
                </div>
              </div>
              <ul tabindex="0" class="mt-3 z-[1] p-2 shadow menu menu-sm dropdown-content bg-base-100 rounded-box w-52">
                <li><a href="/logout">Logout</a></li>
              </ul>
            </div>
          </div>
        </div>

        <!-- Main Content -->
        <div class="p-2 overflow-x-auto">
          <div class="min-w-[1024px]">
            <!-- Character Headers -->
            <div class="grid grid-cols-[repeat(4,minmax(250px,1fr))] gap-1 mb-2 sticky top-16 z-40">
              <%= for character <- @characters do %>
                <div class="relative h-12 overflow-hidden rounded bg-base-100 shadow border border-base-content/10">
                  <%= if character.emblem_background_path do %>
                    <img src={"https://www.bungie.net#{character.emblem_background_path}"} class="absolute inset-0 w-full h-full object-cover opacity-80" />
                  <% end %>
                  <div class="absolute inset-0 flex items-center justify-between px-3 bg-black/40 backdrop-blur-[1px]">
                    <div class="text-white font-bold text-shadow">
                      <div class="text-sm uppercase tracking-wide"><%= class_name(character.class_type) %></div>
                      <div class="text-xs opacity-80"><%= character.light_level %></div>
                    </div>
                    <img src={"https://www.bungie.net#{character.emblem_background_path}"} class="w-8 h-8 rounded-sm border border-white/20" />
                  </div>
                </div>
              <% end %>
              <!-- Vault Header -->
              <div class="relative h-12 overflow-hidden rounded bg-base-100 shadow border border-base-content/10 flex items-center justify-center">
                <div class="font-bold text-lg text-base-content/70">VAULT</div>
              </div>
            </div>

            <!-- Inventory Grid -->
            <div class="space-y-4">
              <%= for {category, label} <- [
                {:weapons, "Weapons"},
                {:armor, "Armor"},
                {:general, "General"}
              ] do %>
                <div class="bg-base-200/50 p-2 rounded-lg">
                  <h3 class="text-sm font-bold uppercase tracking-widest opacity-50 mb-2 ml-1"><%= label %></h3>
                  
                  <%= for bucket <- buckets_for_category(category) do %>
                    <div class="mb-1">
                      <div class="grid grid-cols-[repeat(4,minmax(250px,1fr))] gap-1">
                        <%= for character <- @characters do %>
                          <div class="bg-base-100/50 rounded p-1 min-h-[60px] flex flex-wrap gap-1 content-start">
                            <%= for item <- get_items(@items, character.id, bucket) do %>
                              <.item_icon item={item} />
                            <% end %>
                          </div>
                        <% end %>
                        <!-- Vault Column -->
                        <div class="bg-base-100/50 rounded p-1 min-h-[60px] flex flex-wrap gap-1 content-start">
                          <%= for item <- get_items(@vault_items, nil, bucket) do %>
                            <.item_icon item={item} />
                          <% end %>
                        </div>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp buckets_for_category(:weapons), do: [@bucket_hashes.kinetic, @bucket_hashes.energy, @bucket_hashes.power]
  defp buckets_for_category(:armor), do: [@bucket_hashes.helmet, @bucket_hashes.gauntlets, @bucket_hashes.chest, @bucket_hashes.leg, @bucket_hashes.class]
  defp buckets_for_category(:general), do: [@bucket_hashes.ghost, @bucket_hashes.vehicle, @bucket_hashes.ship]

  defp get_items(items, character_id, bucket_hash) do
    Enum.filter(items, fn item -> 
      (is_nil(character_id) or item.character_id == character_id) and 
      item.bucket_hash == bucket_hash 
    end)
    |> Enum.sort_by(&(&1.power_level), :desc)
  end

  defp class_name(0), do: "Titan"
  defp class_name(1), do: "Hunter"
  defp class_name(2), do: "Warlock"
  defp class_name(_), do: "Unknown"

  attr :item, Destiny2.Items.Item, required: true
  
  defp item_icon(assigns) do
    # Try to find definition
    definition = Definitions.get_definition(assigns.item.item_hash)
    assigns = assign(assigns, :definition, definition)
    
    ~H"""
    <div class="relative w-10 h-10 bg-base-300 rounded overflow-hidden group cursor-pointer border border-base-content/10 hover:border-primary transition-colors" title={item_name(@definition)}>
      <%= if @definition && @definition.json_data["displayProperties"]["icon"] do %>
        <img src={"https://www.bungie.net#{@definition.json_data["displayProperties"]["icon"]}"} class="w-full h-full object-cover" />
      <% else %>
        <div class="w-full h-full flex items-center justify-center text-[10px] text-center leading-none p-0.5">?</div>
      <% end %>
      
      <%= if @item.power_level do %>
        <div class="absolute bottom-0 right-0 bg-black/70 text-[9px] text-white px-0.5 rounded-tl">
          <%= @item.power_level %>
        </div>
      <% end %>
      
      <%= if @item.is_equipped do %>
        <div class="absolute top-0 left-0 w-2 h-2 bg-white border border-black"></div>
      <% end %>
    </div>
    """
  end
  
  defp item_name(nil), do: "Unknown Item"
  defp item_name(definition), do: definition.json_data["displayProperties"]["name"]
end
