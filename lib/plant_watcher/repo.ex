defmodule PlantWatcher.Repo do
  use Ecto.Repo,
    otp_app: :plant_watcher,
    adapter: Ecto.Adapters.Postgres
end
