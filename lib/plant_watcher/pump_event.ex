defmodule PlantWatcher.PumpEvent do
  use Ecto.Schema
  import Ecto.Query
  alias PlantWatcher.Repo

  schema "device_pump_time" do
    field :time, :naive_datetime
  end

  # get times of pumps within charting params
  def get_pump_times(time_start, time_end) do
    from(g in __MODULE__,
      where: g.time >= ^time_start and g.time <= ^time_end,
      order_by: [asc: g.time]
    )
    |> Repo.all()
    |> Enum.map(fn row ->
      %{ pump_time: row.time }
    end)
  end
end
