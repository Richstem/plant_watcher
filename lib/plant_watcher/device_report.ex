defmodule PlantWatcher.DeviceReport do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "device_reports" do
    field :time, :naive_datetime_usec
    field :device_temp, :float
    field :soil_temp, :float
    field :soil_moisture, :float
  end

  def changeset(device_report, attrs) do
    device_report
    |> cast(attrs, [:time, :device_temp, :soil_temp, :soil_moisture])
    |> validate_required([:time])
  end

end
