defmodule Mudan.Repo do
  use Ecto.Repo,
    otp_app: :mudan,
    adapter: Ecto.Adapters.Postgres
end
