defmodule Exaudio do

  ## Types

  @type format :: :float32 | :int32 | :int24 | :int16 | :int8 | :uint8

  @type error :: :not_initialized | :unanticipated_host_error |
                  :invalid_number_of_channels | :invalid_sample_rate |
                  :invalid_device | :invalid_flag | :sample_format_unsupported |
                  :bad_device_combo | :insufficient_memory | :buffer_too_big |
                  :buffer_too_small | :nocallback | :badcallback | :timeout |
                  :internal_error | :device_unavailable |
                  :incompatible_host_stream_info | :stream_stopped |
                  :stream_not_stopped | :input_overflowed | :output_underflowed |
                  :no_hostapi | :invalid_hostapi | :noread_callback |
                  :nowrite_callback | :output_only | :input_only |
                  :incompatible_hostapi | :badbuffer | :unknownerror

  @type pa_error :: {:error, error}

  ## Devices

  @spec default_input_device :: %Exaudio.Device{}
  def default_input_device do
    :erlaudio.default_input_device
    |> Exaudio.Device.new
  end

  @spec default_input_device :: %Exaudio.Device{}
  def default_output_device do
    :erlaudio.default_output_device
    |> Exaudio.Device.new
  end

  @spec device(integer) :: %Exaudio.Device{}
  def device(index) do
    :erlaudio.device(index)
    |> Exaudio.Device.new
  end

  @spec devices :: [%Exaudio.Device{}]
  def devices do
    :erlaudio.devices
    |> Enum.map(&Exaudio.Device.new/1)
  end

  ## Device params

  @spec default_input_params(format) :: %Exaudio.DeviceParams{}
  def default_input_params(sample_format) do
    :erlaudio.default_input_params(sample_format)
    |> Exaudio.DeviceParams.new
  end

  @spec default_output_params(format) :: %Exaudio.DeviceParams{}
  def default_output_params(sample_format) do
    :erlaudio.default_output_params(sample_format)
    |> Exaudio.DeviceParams.new
  end

  @spec input_device_params(%Exaudio.Device{} | integer, format) :: %Exaudio.DeviceParams{}
  def input_device_params(index, sample_format) when is_integer(index) do
    :erlaudio.input_device_params(index, sample_format)
    |> Exaudio.DeviceParams.new
  end
  def input_device_params(%Exaudio.Device{} = device, sample_format) do
    device
    |> Exaudio.Device.to_record
    |> :erlaudio.input_device_params(sample_format)
    |> Exaudio.DeviceParams.new
  end

  @spec output_device_params(%Exaudio.Device{} | integer, format) :: %Exaudio.DeviceParams{}
  def output_device_params(index, sample_format) when is_integer(index) do
    :erlaudio.output_device_params(index, sample_format)
    |> Exaudio.DeviceParams.new
  end
  def output_device_params(%Exaudio.Device{} = device, sample_format) do
    device
    |> Exaudio.Device.to_record
    |> :erlaudio.output_device_params(sample_format)
    |> Exaudio.DeviceParams.new
  end

  ## Streams

  ## Portaudio

  @spec portaudio_version :: {integer, String.t}
  def portaudio_version, do: :erlaudio.portaudio_version
end
