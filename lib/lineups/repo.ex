defmodule Lineups.Repo do
  use Ecto.Repo,
    otp_app: :lineups,
    adapter: Ecto.Adapters.Postgres
end
