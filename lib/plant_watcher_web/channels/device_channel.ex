defmodule PlantWatcherWeb.DeviceChannel do
  use PlantWatcherWeb, :channel
  alias PlantWatcher.Repo
  alias PlantWatcher.DeviceReport
  require Logger

  def join("device:temp", _payload, socket) do
    {:ok, socket}
  end

  def handle_in(
        "report_temp",
        %{"temp" => temp, "soil_temp" => soil_temp, "soil_moisture" => soil_moisture},
        socket
      ) do
        # let's show user the values we got from device before committing to db.
        Phoenix.PubSub.broadcast!(
          PlantWatcher.PubSub,
          "temp_updates",
          {:new_stats, %{temp: temp, soil_temp: soil_temp, soil_moisture: soil_moisture}}
        )
        # Then we can handle db ops. Let's check if they're floats and if not, we'll add nulls to track missing data
        db_device_temp = if is_number(temp), do: temp
        db_soil_temp = if is_number(soil_temp), do: soil_temp
        db_soil_moisture = if is_number(soil_moisture), do: soil_moisture

        report_params = %{
          time: NaiveDateTime.local_now(),
          device_temp: db_device_temp,
          soil_temp: db_soil_temp,
          soil_moisture: db_soil_moisture
        }

        commit_to_db(report_params)

    {:noreply, socket}
  end

  defp commit_to_db(report_params) do
    case %DeviceReport{}
      |> DeviceReport.changeset(report_params)
      |> Repo.insert() do
        {:ok, _struct} -> :ok
        {:error, changeset} -> Logger.error("Db save failed. #{inspect(changeset.errors)}")
      end
  end

end
