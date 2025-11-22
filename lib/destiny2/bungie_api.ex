defmodule Destiny2.BungieAPI do
  @moduledoc """
  Client for interacting with the Bungie API.
  """

  @base_url "https://www.bungie.net/Platform"

  defp api_key do
    Application.get_env(:destiny2, :bungie_api_key) || System.get_env("BUNGIE_API_KEY")
  end

  defp headers(access_token) do
    base_headers = [
      {"X-API-Key", api_key()},
      {"Content-Type", "application/json"}
    ]

    if access_token do
      [{"Authorization", "Bearer #{access_token}"} | base_headers]
    else
      base_headers
    end
  end

  defp handle_response({:ok, %{status: 200, body: body}}) when is_map(body) do
    case body do
      %{"Response" => response, "ErrorCode" => 1} -> {:ok, response}
      %{"ErrorCode" => code, "ErrorStatus" => status} -> {:error, "#{status} (#{code})"}
      data -> {:ok, data}
    end
  end

  defp handle_response({:ok, %{status: 200, body: body}}) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, %{"Response" => response, "ErrorCode" => 1}} -> {:ok, response}
      {:ok, %{"ErrorCode" => code, "ErrorStatus" => status}} -> {:error, "#{status} (#{code})"}
      {:ok, data} -> {:ok, data}
      error -> error
    end
  end

  defp handle_response({:ok, %{status: status}}) do
    {:error, "HTTP #{status}"}
  end

  defp handle_response(error), do: error

  def get_profile(membership_type, membership_id, access_token, components \\ [200]) do
    components_str = Enum.join(components, ",")

    "#{@base_url}/Destiny2/#{membership_type}/Profile/#{membership_id}/?components=#{components_str}"
    |> Req.get(headers: headers(access_token))
    |> handle_response()
  end

  def get_character(
        membership_type,
        membership_id,
        character_id,
        access_token,
        components \\ [200]
      ) do
    components_str = Enum.join(components, ",")

    "#{@base_url}/Destiny2/#{membership_type}/Profile/#{membership_id}/Character/#{character_id}/?components=#{components_str}"
    |> Req.get(headers: headers(access_token))
    |> handle_response()
  end

  def get_vault(membership_type, membership_id, access_token, components \\ [102]) do
    components_str = Enum.join(components, ",")

    "#{@base_url}/Destiny2/#{membership_type}/Profile/#{membership_id}/Character/0/?components=#{components_str}"
    |> Req.get(headers: headers(access_token))
    |> handle_response()
  end

  def get_current_user(access_token) do
    "#{@base_url}/User/GetCurrentBungieNetUser/"
    |> Req.get(headers: headers(access_token))
    |> handle_response()
  end

  def get_memberships_for_current_user(access_token) do
    "#{@base_url}/User/GetMembershipsForCurrentUser/"
    |> Req.get(headers: headers(access_token))
    |> handle_response()
  end

  def get_access_token(code) do
    config = Application.get_env(:destiny2, :bungie)

    body =
      URI.encode_query(%{
        grant_type: "authorization_code",
        code: code,
        client_id: config[:client_id],
        client_secret: config[:client_secret]
      })

    "https://www.bungie.net/Platform/App/OAuth/token/"
    |> Req.post(
      body: body,
      headers: [{"Content-Type", "application/x-www-form-urlencoded"}]
    )
    |> handle_token_response()
  end

  def refresh_access_token(refresh_token) do
    config = Application.get_env(:destiny2, :bungie)

    body =
      URI.encode_query(%{
        grant_type: "refresh_token",
        refresh_token: refresh_token,
        client_id: config[:client_id],
        client_secret: config[:client_secret]
      })

    "https://www.bungie.net/Platform/App/OAuth/token/"
    |> Req.post(
      body: body,
      headers: [{"Content-Type", "application/x-www-form-urlencoded"}]
    )
    |> handle_token_response()
  end

  defp handle_token_response({:ok, %{status: 200, body: body}}) do
    {:ok, body}
  end

  defp handle_token_response({:ok, %{status: status, body: body}}) do
    {:error, "HTTP #{status}: #{inspect(body)}"}
  end

  defp handle_token_response(error), do: error

  def get_entity_definition(entity_type, hash) do
    # This endpoint doesn't require auth usually, but we'll pass the API key in headers
    "#{@base_url}/Destiny2/Manifest/#{entity_type}/#{hash}/"
    |> Req.get(headers: headers(nil))
    |> handle_response()
  end
end
