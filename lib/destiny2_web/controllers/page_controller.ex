defmodule Destiny2Web.PageController do
  use Destiny2Web, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
