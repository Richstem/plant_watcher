# lib/plant_watcher_web/live/temperature_live.ex
defmodule PlantWatcherWeb.TemperatureLive do
  use PlantWatcherWeb, :live_view

  # on mount let's assign a temp value so we know it's awating data
  def mount(_params, _session, socket) do
    # Subscribe to the PubSub topic
    if connected?(socket) do
      Phoenix.PubSub.subscribe(PlantWatcher.PubSub, "temp_updates")
      Phoenix.PubSub.subscribe(PlantWatcher.PubSub, "successful_pump")
    end

    #update_chart_data(socket)
    last_6h = PlantWatcher.LiveGraph.get_last_6h()
    socket = push_event(socket, "load_history", %{data: last_6h})

    # set up timer to reload chart every 60 s
    :timer.send_interval(60000, :refresh_chart)

    socket =
     socket
      |> assign(:current_temp, "Waiting...")
      |> assign(:soil_temp, "Waiting...")
      |> assign(:soil_moisture, "Waiting...")
      |> assign(selected_duration: 10, error_message: nil, success_message: nil, selected_timeframe: "6h" )
      |> update_chart_data()

    {:ok, socket}
  end

  # Catch PubSub successful_pump topic and flash it
  def handle_info({:pump_success, data}, socket) do
    time_string = Calendar.strftime(data.time, "%I:%M:%S %p")
    socket =
      socket
      |> put_flash(:info, "Successfully pumped and logged at #{time_string}")
    {:noreply, socket}
  end

  # Catch PubSub successful_pump topic and flash it
  def handle_info({:pump_db_fail, _data}, socket) do
    socket =
      socket
      |> put_flash(:error, "Successfully pumped but failed to log.")
    {:noreply, socket}
  end

  # Catch the PubSub message sent from the Channel and pass to render fxn
  def handle_info({:new_stats, stats}, socket) do
    {:noreply,
     socket
     |> assign(:current_temp, "#{stats.temp}" <> " F")
     |> assign(:soil_temp, "#{stats.soil_temp}" <> " F")
     |> assign(:soil_moisture, "#{stats.soil_moisture}")}
  end

  # Update chart on page based on interval set in mount function
  def handle_info(:refresh_chart, socket) do
    socket = update_chart_data(socket)
    {:noreply, socket}
  end

  def handle_event("update_duration", %{"duration" => duration}, socket) do
    user_selected_duration = String.to_integer(duration)
    {:noreply, assign(socket, %{selected_duration: user_selected_duration})}
  end

  # Check env for pump water code, validate and broadcast.
  def handle_event("pump_water", %{"code" => code, "duration" => duration_str}, socket) do
    valid_code = Application.get_env(:plant_watcher, :pump_water_code)

    case code do
      ^valid_code ->
        duration = String.to_integer(duration_str)
        topic = "device:temp"

        PlantWatcherWeb.Endpoint.broadcast(topic, "pump_water", %{duration: duration})

        {:noreply,
         assign(socket, %{
           error_message: nil,
           success_message: "Success! pumping for #{duration_str} seconds"
         })}

      _ ->
        {:noreply, assign(socket, %{error_message: "Invalid Code!", success_message: ""})}
    end
  end

  # update selected timeframe and update chart
  def handle_event("change_timeframe", %{"timeframe" => timeframe}, socket) do
    socket =
      socket
      |> assign(:selected_timeframe, timeframe)
      |> update_chart_data()

    {:noreply, socket}
  end

  # clear error message when retyping code
  def handle_event("clear_err_on_type", _params, socket) do
    {:noreply, assign(socket, %{error_message: "", success_message: ""})}
  end

  # update chart on interval call
  defp update_chart_data(socket) do
    if connected?(socket) do
      chart_data =
        case socket.assigns.selected_timeframe do
          "6h" ->
            PlantWatcher.LiveGraph.get_last_6h()
          selected_range ->
            time_end = NaiveDateTime.local_now()
            time_start = calculate_start_time(selected_range, time_end)
            PlantWatcher.CustomGraph.get_custom_graph(time_start, time_end)
        end

      push_event(socket, "load_history", %{data: chart_data})
    else
      socket
    end
  end

  # Find our start datetimes based on now.
  defp calculate_start_time("6h", now), do: NaiveDateTime.shift(now, hour: -6)
  defp calculate_start_time("24h", now), do: NaiveDateTime.shift(now, hour: -24)
  defp calculate_start_time("7d", now), do: NaiveDateTime.shift(now, day: -7)
  defp calculate_start_time("30d", now), do: NaiveDateTime.shift(now, day: -30)
  defp calculate_start_time(_, now), do: NaiveDateTime.shift(now, hour: -6)



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
        input[type="range"] {
          accent-color: green;
        }
        </style>

      <div>
        <div class="stats-wrapper">

    <!--Soil temp section -->
          <div class="text-center mt-10">
            <h1 class="text-2xl font-bold">Soil Temperature</h1>
            <div class="text-6xl mt-4 font-mono text-blue-600">
              {@soil_temp}
            </div>
          </div>

    <!--Soil moisture section -->
          <div class="text-center mt-10">
            <h1 class="text-2xl font-bold">Moisture Reading</h1>
            <div class="text-6xl mt-4 font-mono text-green-600">
              {@soil_moisture}
            </div>
          </div>

    <!--Device temp section -->
          <div class="text-center mt-10">
            <h1 class="text-2xl font-bold">Device Temperature</h1>
            <div class="text-6xl mt-4 font-mono text-red-600">
              {@current_temp}
            </div>
          </div>
        </div>

    <!-- Timeframe Dropdown-->
        <div class="w-full max-w-md sm:max-w-4xl lg:max-w-7xl mx-auto my-6 px-2">
          <div class="flex justify-center mb-2">
            <form phx-change="change_timeframe">
              <label for="timeframe" class="text-lg font-bold text-white-700 mr-2">Chart Timeframe:</label>
              <select id="timeframe" name="timeframe"
                      class="rounded border border-gray-300 py-2 px-2 text-sm bg-white text-gray-900 dark:bg-gray-800 dark:text-white dark:border-gray-600">
                <option value="6h" selected={@selected_timeframe == "6h"}>Last 6 Hours</option>
                <option value="24h" selected={@selected_timeframe == "24h"}>Last 24 Hours</option>
                <option value="7d" selected={@selected_timeframe == "7d"}>Last 7 Days</option>
                <option value="30d" selected={@selected_timeframe == "30d"}>Last 30 Days</option>
              </select>
            </form>
          </div>

          <!-- Chart -->

            <div class="bg-white p-2 sm:p-4 border rounded-xl shadow-md relative h-[280px] sm:h-96">
              <canvas id="telemetry-chart" phx-hook="LineChart" phx-update="ignore"></canvas>
            </div>

        </div>

    <!-- Pump Water Form -->

        <div class="my-10 p-6 bg-gray-100 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-md max-w-md mx-auto">
          <.form for={%{}} phx-submit="pump_water" class="space-y-4 ">
            <div>
              <label class="block text-sm text-black dark:text-white font-bold">Enter Code</label>
              <input
                type="password"
                name="code"
                phx-change="clear_err_on_type"
                class="w-full rounded border-red-300 text-black dark:text-white"
                placeholder="Enter Code"
                maxlength="10"
                required
              />
              <%= if @error_message do %>
                <p class="text-red-500 text-left mt-2">{@error_message}</p>
              <% end %>
              <%= if @success_message do %>
                <p class="text-green-500 text-left mt-2">{@success_message}</p>
              <% end %>
            </div>
            <div>
              <label class="block text-md text-black dark:text-white font-bold">
                Pump duration: {@selected_duration} seconds
              </label>
              <input
                type="range"
                name="duration"
                min="5"
                max="20"
                step="1"
                value={@selected_duration}
                phx-change="update_duration"
                class="w-full text-white"
              />
            </div>
            <button
              type="submit"
              class="bg-green-700 hover:bg-green-900 text-white font-bold py-2 px-4 rounded"
            >
              Authorize and Pump!
            </button>
          </.form>
        </div>
      </div>
    </section>
    """
  end
end
