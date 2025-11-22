defmodule Destiny2.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query, warn: false
  alias Destiny2.Repo
  alias Destiny2.Users.User

  def get_user_by_membership(membership_id, membership_type) do
    Repo.get_by(User, membership_id: membership_id, membership_type: membership_type)
  end

  def get_user(id), do: Repo.get(User, id)

  def create_or_update_user(attrs) do
    case get_user_by_membership(attrs.membership_id, attrs.membership_type) do
      nil ->
        %User{}
        |> User.changeset(attrs)
        |> Repo.insert()

      user ->
        user
        |> User.changeset(attrs)
        |> Repo.update()
    end
  end

  def update_user_tokens(user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end
end
