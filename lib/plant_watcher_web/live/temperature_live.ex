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
    |> assign(selected_duration: 10, error_message: nil, success_message: nil)
    }
  end

  # Catch the PubSub message sent from the Channel and pass to render fxn
  def handle_info({:new_stats, stats}, socket) do
    {:noreply,
    socket
    |> assign(:current_temp, stats.temp<>" F")
    |> assign(:soil_temp, stats.soil_temp<>" F")
    |> assign(:soil_moisture, stats.soil_moisture)
    }
  end

  def handle_event("update_duration", %{"duration" => duration}, socket) do
    user_selected_duration = String.to_integer(duration)
    {:noreply, assign(socket, %{selected_duration: user_selected_duration})}
  end

  # Check env for pump water code, validate and broadcast.
  def handle_event("pump_water", %{ "code" => code, "duration" => duration_str}, socket) do
    valid_code = Application.get_env(:plant_watcher, :pump_water_code)

    case code do
      ^valid_code ->
        duration = String.to_integer((duration_str))
        topic = "device:temp"

        PlantWatcherWeb.Endpoint.broadcast(topic, "pump_water", %{duration: duration})
        {:noreply, assign(socket, %{error_message: nil, success_message: "Success! pumping for #{duration_str} seconds"})}
      _ ->
        {:noreply, assign(socket, %{error_message: "Invalid Code!", success_message: "" })}

    end
  end

  def handle_event("clear_err_on_type", _params, socket) do
    {:noreply, assign(socket, %{error_message: "", success_message: ""})}
  end

  def render(assigns) do
    ~H"""

      <section>
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

          <!-- Pump Water Form -->

          <div class="my-10 p-6 bg-gray-700 rounded-lg shadow-md max-w-md mx-auto">
            <.form for={%{}} phx-submit="pump_water" class="space-y-4">
              <div>
                <label class="block text-sm text-white font-bold">Enter Code</label>
                <input type="password"
                  name="code"
                  phx-change="clear_err_on_type"
                  class="w-full rounded border-red-300 text-white"
                  placeholder="Enter Code"
                  maxlength="10"
                  required />
                <%= if @error_message do %>
                  <p class="text-red-500 text-left mt-2"><%= @error_message %></p>
                <% end %>
                <%= if @success_message do %>
                  <p class="text-green-500 text-left mt-2"><%= @success_message %></p>
                <% end %>
              </div>
              <div>
                <label class="block text-sm text-white font-bold">Pump duration: {@selected_duration} seconds</label>
                <input type="range" name="duration" min="5" max="20" step="1"
                    value={@selected_duration} phx-change="update_duration"
                    class="w-full text-white" />
              </div>
              <button type="submit"
                class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
                Authorize and Pump!
              </button>
            </.form>


          </div>
        </div>
      </section>

    """
  end
end
