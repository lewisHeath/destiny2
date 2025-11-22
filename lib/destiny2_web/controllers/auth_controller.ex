defmodule Destiny2Web.AuthController do
  use Destiny2Web, :controller

  alias Destiny2.BungieAPI
  alias Destiny2.Users

  def callback(conn, %{"code" => code}) do
    with {:ok, token_data} <- BungieAPI.get_access_token(code),
         {:ok, user_data} <-
           BungieAPI.get_memberships_for_current_user(token_data["access_token"]) do
      # Find the primary destiny membership
      # Bungie returns a list of memberships. We prefer the one that matches the cross save setup or the first one.
      # The structure of user_data from GetMembershipsForCurrentUser is:
      # %{
      #   "destinyMemberships" => [...],
      #   "primaryMembershipId" => "...",
      #   "bungieNetUser" => %{...}
      # }

      primary_membership_id = user_data["primaryMembershipId"]
      memberships = user_data["destinyMemberships"]

      membership =
        if primary_membership_id do
          Enum.find(memberships, fn m -> m["membershipId"] == primary_membership_id end)
        else
          List.first(memberships)
        end

      if membership do
        user_attrs = %{
          membership_id: membership["membershipId"],
          membership_type: membership["membershipType"],
          display_name: membership["displayName"],
          access_token: token_data["access_token"],
          refresh_token: token_data["refresh_token"],
          token_expires_at: DateTime.add(DateTime.utc_now(), token_data["expires_in"], :second),
          refresh_expires_at:
            DateTime.add(DateTime.utc_now(), token_data["refresh_expires_in"], :second),
          profile_picture_path: user_data["bungieNetUser"]["profilePicturePath"]
        }

        case Users.create_or_update_user(user_attrs) do
          {:ok, user} ->
            conn
            |> put_session(:user_id, user.id)
            |> put_flash(:info, "Successfully logged in!")
            |> redirect(to: ~p"/profile")

          {:error, _changeset} ->
            conn
            |> put_flash(:error, "Failed to create user record")
            |> redirect(to: ~p"/")
        end
      else
        conn
        |> put_flash(:error, "No Destiny 2 membership found")
        |> redirect(to: ~p"/")
      end
    else
      {:error, reason} ->
        conn
        |> put_flash(:error, "Authentication failed: #{inspect(reason)}")
        |> redirect(to: ~p"/")
    end
  end

  def callback(conn, _params) do
    conn
    |> put_flash(:error, "Missing authorization code")
    |> redirect(to: ~p"/")
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> redirect(to: ~p"/")
  end
end
