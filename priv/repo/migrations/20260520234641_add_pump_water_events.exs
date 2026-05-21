defmodule PlantWatcher.Repo.Migrations.AddPumpWaterEvents do
  use Ecto.Migration

  def change do
    create table(:device_pump_time) do
      add :time, :naive_datetime, null: false
    end
  end
end
