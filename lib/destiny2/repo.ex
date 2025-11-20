defmodule Destiny2.Repo do
  use Ecto.Repo,
    otp_app: :destiny2,
    adapter: Ecto.Adapters.Postgres
end
