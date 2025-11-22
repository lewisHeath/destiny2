defmodule Destiny2Web.PageController do
  use Destiny2Web, :controller

  plug :fetch_current_user

  def home(conn, _params) do
    render(conn, :home)
  end

  defp fetch_current_user(conn, _opts) do
    case get_session(conn, :user_id) do
      nil ->
        assign(conn, :current_user, nil)

      user_id ->
        user = Destiny2.Users.get_user(user_id)
        assign(conn, :current_user, user)
    end
  end
end
