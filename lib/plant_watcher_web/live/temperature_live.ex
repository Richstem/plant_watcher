# lib/plant_watcher_web/live/temperature_live.ex
defmodule PlantWatcherWeb.TemperatureLive do
  use PlantWatcherWeb, :live_view

  # on mount let's assign a temp value so we know it's awating data
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

  # Catch the PubSub message sent from the Channel and pass to render fxn
  def handle_info({:new_stats, stats}, socket) do
    {:noreply,
    socket
    |> assign(:current_temp, stats.temp)
    |> assign(:soil_temp, stats.soil_temp)
    |> assign(:soil_moisture, stats.soil_moisture)
    }
  end

  # Hande
  def handle_event("pump_water", {:duration, duration }, socket) do

  end

  def render(assigns) do
    ~H"""
    <style>
      .stats-wrapper {
        display: flex;
        justify-content: space-evenly;
        flex-wrap: wrap;
      }
      .btn-wrapper {
        display: flex;
        justify-content: center;

      }
    </style>

    <div>
      <div class="stats-wrapper">

        <!--Soil temp section -->
        <div class="text-center mt-10">
          <h1 class="text-2xl font-bold">Soil Temperature</h1>
          <div class="text-6xl mt-4 font-mono text-green-600">
            <%= @soil_temp %>
          </div>
        </div>

          <!--Soil moisture section -->
        <div class="text-center mt-10">
            <h1 class="text-2xl font-bold">Moisture Reading</h1>
            <div class="text-6xl mt-4 font-mono text-green-600">
              <%= @soil_moisture %>
            </div>
        </div>

        <!--Device temp section -->
        <div class="text-center mt-10">
          <h1 class="text-2xl font-bold">Device Temperature</h1>
          <div class="text-6xl mt-4 font-mono text-green-600">
            <%= @current_temp %>
          </div>
        </div>
      </div>
      <div class="btn-wrapper my-10">
        <button
          phx-click="pump_water"
          phx-value-duration="15"
          class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
            Water your plants
        </button>
      </div>


    </div>

    """
  end
end
