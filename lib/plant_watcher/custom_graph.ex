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
        soil_moisture: row.avg_soil_moisture
      }
    end)
  end
end
