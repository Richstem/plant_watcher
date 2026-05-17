defmodule PlantWatcher.Repo.Migrations.AddDataRetentionPolicy do
  use Ecto.Migration

  @disable_ddl_transaction

  def up do
    execute """
      SELECT add_retention_policy('device_reports', INTERVAL '7 days');
    """
  end

  def down do
    execute """
      SELECT remove_retention_policy('device_reports');
    """
  end
end
