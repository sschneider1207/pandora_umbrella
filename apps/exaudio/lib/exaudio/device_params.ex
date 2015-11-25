defmodule Exaudio.DeviceParams do

  defstruct index: nil, channel_count: nil, sample_format: nil, suggested_latency: nil

  @type t :: %__MODULE__{
    index: integer, channel_count: integer,
    sample_format: Exaudio.format, suggested_latency: float}

  def new({:erlaudio_device_params, index, channel_count, sample_format, suggested_latency}) do
    %__MODULE__{
      index: index, channel_count: channel_count,
      sample_format: sample_format, suggested_latency: suggested_latency}
  end

  def to_record(
    %__MODULE__{
      index: index, channel_count: channel_count,
      sample_format: sample_format, suggested_latency: suggested_latency}
  ) do
    {:erlaudio_device_params, index, channel_count, sample_format, suggested_latency}
  end
end
