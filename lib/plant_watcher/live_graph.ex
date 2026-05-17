defmodule PlantWatcher.LiveGraph do
  use Ecto.Schema
  import Ecto.Query
  alias PlantWatcher.Repo

  @primary_key false

  schema "device_live_graph" do
    field :bucket, :naive_datetime
    field :avg_device_temp, :float
    field :avg_soil_temp, :float
    field :avg_soil_moisture, :float
  end

  def get_last_6h() do
    from(g in __MODULE__,
      where: g.bucket > fragment("NOW() - INTERVAL '6 hours'"),
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
