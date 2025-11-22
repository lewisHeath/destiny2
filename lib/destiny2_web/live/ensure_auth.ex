defmodule Destiny2Web.Live.EnsureAuth do
  import Phoenix.LiveView
  import Phoenix.Component

  alias Destiny2.Users

  def on_mount(:ensure_authenticated, _params, session, socket) do
    case Map.get(session, "user_id") do
      nil ->
        {:halt,
         socket
         |> put_flash(:error, "You must be logged in to access this page")
         |> redirect(to: "/")}

      user_id ->
        case Users.get_user(user_id) do
          nil ->
            {:halt,
             socket
             |> put_flash(:error, "Session expired. Please log in again.")
             |> redirect(to: "/")}

          user ->
            {:cont, assign(socket, :current_user, user)}
        end
    end
  end
end
