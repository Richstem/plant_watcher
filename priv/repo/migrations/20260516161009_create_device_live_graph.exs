defmodule PlantWatcher.Repo.Migrations.CreateDeviceLiveGraph do
  use Ecto.Migration

  # can't run add_continuous_aggregate_policy in a transaction, so lets disable it
  # if rollback needed, run mix.ecto.rollback manually to remove the materialized view
  @disable_ddl_transaction true

  def up do   # lets handle up and down migrations separately
    #create the view
    execute """
      CREATE MATERIALIZED VIEW device_live_graph
      WITH (timescaledb.continuous = true) AS
        SELECT
          time_bucket('1 minute', time) AS bucket,
          AVG(soil_temp) AS avg_soil_temp,
          AVG(soil_moisture) AS avg_soil_moisture,
          AVG(device_temp) AS avg_device_temp
        FROM device_reports
        GROUP BY bucket;
      """
    # create the refresh policy (look back 2 hrs for any late data, and run aggregate query every 1 mins)
    execute """
      SELECT add_continuous_aggregate_policy(
      'device_live_graph',
      start_offset => INTERVAL '2 hours',
      end_offset => INTERVAL '1 minute',
      schedule_interval => INTERVAL '1 minute');
    """
  end

  def down do
    execute """
      DROP MATERIALIZED VIEW IF EXISTS device_live_graph;
    """
  end
end
