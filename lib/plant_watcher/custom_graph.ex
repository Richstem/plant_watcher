defmodule PlantWatcher.CustomGraph do
  use Ecto.Schema
  import Ecto.Query
  alias PlantWatcher.Repo

  @primary_key false

  schema "device_reports_15min" do
    field :bucket, :naive_datetime
    field :avg_device_temp, :float
    field :avg_soil_temp, :float
    field :avg_soil_moisture, :float
  end

  def get_custom_graph(time_start, time_end) do
    time_dif_string =
      case NaiveDateTime.diff(time_end,time_start, :hour) do
        6 ->
          "Last 6 Hours"
        24 ->
          "Last 24 Hours"
        168 ->
          "Last 7 Days"
        720 ->
          "Last 30 Days"
        _ ->
          "Default"
      end
    from(g in __MODULE__,
      where: g.bucket >= ^time_start and g.bucket <= ^time_end,
      order_by: [asc: g.bucket]
    )
    |> Repo.all()
    |> Enum.map(fn row ->
      %{
        time: row.bucket,
        device_temp: row.avg_device_temp,
        soil_temp: row.avg_soil_temp,
        soil_moisture: row.avg_soil_moisture,
        time_dif: time_dif_string
      }
    end)

  end
end
