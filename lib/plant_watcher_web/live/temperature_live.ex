# lib/plant_watcher_web/live/temperature_live.ex
defmodule PlantWatcherWeb.TemperatureLive do
  use PlantWatcherWeb, :live_view

  def mount(_params, _session, socket) do
    # Subscribe to the PubSub topic
    if connected?(socket), do: Phoenix.PubSub.subscribe(PlantWatcher.PubSub, "temp_updates")

    {:ok,
    socket
    |> assign(:current_temp, "Waiting...")
    |> assign(:soil_temp, "Waiting...")
    |> assign(:soil_moisture, "Waiting...")
    }
  end

  # This function catches the PubSub message sent from the Channel
  def handle_info({:new_stats, stats}, socket) do
    {:noreply,
    socket
    |> assign(:current_temp, stats.temp)
    |> assign(:soil_temp, stats.soil_temp)
    |> assign(:soil_moisture, stats.soil_moisture)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="text-center mt-10">
      <h1 class="text-2xl font-bold">Device Temperature</h1>
      <div class="text-6xl mt-4 font-mono text-green-600">
        <%= @current_temp %>
      </div>
    </div>

    <div class="text-center mt-10">
      <h1 class="text-2xl font-bold">Soil Temperature</h1>
      <div class="text-6xl mt-4 font-mono text-green-600">
        <%= @soil_temp %>
      </div>
    </div>

    <div class="text-center mt-10">
      <h1 class="text-2xl font-bold">Moisture Reading</h1>
      <div class="text-6xl mt-4 font-mono text-green-600">
        <%= @soil_moisture %>
      </div>
    </div>
    """
  end
end
