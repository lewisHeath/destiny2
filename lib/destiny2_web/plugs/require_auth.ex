defmodule Destiny2Web.Plugs.RequireAuth do
  use Destiny2Web, :router
  import Plug.Conn
  import Phoenix.Controller

  alias Destiny2.Users

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :user_id) do
      nil ->
        conn
        |> put_flash(:error, "You must be logged in to access this page")
        |> redirect(to: "/")
        |> halt()

      user_id ->
        case Users.get_user(user_id) do
          nil ->
            conn
            |> clear_session()
            |> put_flash(:error, "Session expired. Please log in again.")
            |> redirect(to: "/")
            |> halt()

          user ->
            assign(conn, :current_user, user)
        end
    end
  end
end
