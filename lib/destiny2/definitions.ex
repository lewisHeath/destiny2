defmodule Destiny2.Definitions do
  @moduledoc """
  The Definitions context.
  """

  import Ecto.Query, warn: false
  alias Destiny2.Repo
  alias Destiny2.Definitions.Definition
  alias Destiny2.BungieAPI

  def get_definition(hash) do
    Repo.get_by(Definition, hash: hash)
  end

  def get_definitions(hashes) do
    Repo.all(from d in Definition, where: d.hash in ^hashes)
  end

  def create_definition(attrs) do
    %Definition{}
    |> Definition.changeset(attrs)
    |> Repo.insert()
  end

  def ensure_definitions(hashes) do
    # Find which hashes we are missing
    existing_hashes = 
      from(d in Definition, where: d.hash in ^hashes, select: d.hash)
      |> Repo.all()
      
    missing_hashes = hashes -- existing_hashes
    
    # Fetch missing definitions from Bungie API
    # We'll do this concurrently
    Task.async_stream(missing_hashes, fn hash ->
      case BungieAPI.get_entity_definition("DestinyInventoryItemDefinition", hash) do
        {:ok, data} ->
          create_definition(%{
            hash: hash,
            json_data: data
          })
        _ -> :error
      end
    end, max_concurrency: 5, timeout: 30_000)
    |> Stream.run()
  end
end
