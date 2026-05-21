defmodule PlantWatcherWeb.DeviceChannel do
  use PlantWatcherWeb, :channel
  alias PlantWatcher.Repo
  alias PlantWatcher.DeviceReport
  alias PlantWatcher.PumpEvent
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

  # handle and commit successful pump to db
  def handle_in(
      "report_successful_pump",
      %{"status" => "success"},
      socket
    ) do
      now = NaiveDateTime.local_now

      case Repo.insert(%PumpEvent {time: now}) do
        {:ok, _struct} ->
          #let's broadcast and flash it to the live-view
          Phoenix.PubSub.broadcast!(
              PlantWatcher.PubSub,
              "successful_pump",
              {:pump_success, %{time: now}}
            )
        {:error, _changeset} ->
          Phoenix.PubSub.broadcast!(
              PlantWatcher.PubSub,
              "successful_pump",
              {:pump_db_fail, %{time: now}}
            )
        end
      {:noreply, socket}
    end

  # handle failed pump
  def handle_in(
    "report_successful_pump",
    %{"status" => other_status},
    socket
  ) do
    Logger.error("pump water command failed!, #{other_status}")
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
