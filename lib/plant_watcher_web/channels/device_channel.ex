defmodule PlantWatcherWeb.DeviceChannel do
  use PlantWatcherWeb, :channel

  def join("device:temp", _payload, socket) do
    {:ok, socket}
  end

  def handle_in("report_temp",
    %{"temp" => temp,
      "soil_temp" => soil_temp,
      "soil_moisture" => soil_moisture},
      socket) do
        Phoenix.PubSub.broadcast!(
            PlantWatcher.PubSub,
            "temp_updates",
            {:new_stats, %{temp: temp, soil_temp: soil_temp, soil_moisture: soil_moisture}}
          )
        {:noreply, socket}
  end
end
