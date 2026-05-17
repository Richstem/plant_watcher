defmodule PlantWatcher.Repo.Migrations.CreateDeviceReports do
  use Ecto.Migration

  def change do
    create table(:device_reports, primary_key: false) do
      add :time, :naive_datetime_usec, null: false
      add :device_temp, :float, null: true
      add :soil_temp, :float, null: true
      add :soil_moisture, :float, null: true
    end

    # Convert table into timescale db hypertable (compresses data and allows fast access to metadata)
    # partitioned by :time
    execute(
      "SELECT create_hypertable('device_reports', 'time');",
      "SELECT 1;" #Down migration query -- table gets deleted on rollback anyway
    )
  end
end
