defmodule Exaudio.Device do
  defstruct index: -1, name: "", host_api: -1,
            max_input_channels: nil, max_output_channels: nil,
            default_low_input_latency: nil, default_low_output_latency: nil,
            default_high_input_latency: nil, default_high_output_latency: nil,
            default_sample_rate: nil

  @type t :: %__MODULE__{
    index: integer, name: String.t, host_api: integer,
    max_input_channels: integer, max_output_channels: integer,
    default_low_input_latency: float, default_low_output_latency: float,
    default_high_input_latency: float, default_high_output_latency: float,
    default_sample_rate: float}

  def new({:erlaudio_device, index, name, host_api, max_input_channels, max_output_channels, default_low_input_latency, default_low_output_latency, default_high_input_latency, default_high_output_latency, default_sample_rate}) do
    %__MODULE__{
      index: index, name: name, host_api: host_api,
      max_input_channels: max_input_channels, max_output_channels: max_output_channels,
      default_low_input_latency: default_low_input_latency, default_low_output_latency: default_low_output_latency,
      default_high_input_latency: default_high_input_latency, default_high_output_latency: default_high_output_latency,
      default_sample_rate: default_sample_rate}
  end

  def to_record(
    %__MODULE__{
      index: index, name: name, host_api: host_api,
      max_input_channels: max_input_channels, max_output_channels: max_output_channels,
      default_low_input_latency: default_low_input_latency, default_low_output_latency: default_low_output_latency,
      default_high_input_latency: default_high_input_latency, default_high_output_latency: default_high_output_latency,
      default_sample_rate: default_sample_rate}
  ) do
    {:erlaudio_device, index, name, host_api, max_input_channels,
    max_output_channels, default_low_input_latency, default_low_output_latency,
    default_high_input_latency, default_high_output_latency, default_sample_rate}
  end
end
