defmodule PandoraPhoenix.PlayerChannel do
  use Phoenix.Channel

  def join("player", _msg, socket) do
    {:ok, socket}
  end

  @doc """
  Retrieves and broadcast's the current station list.  A checksum may be provided,
  in which case the station list will only be broadcasted if the checksum is out
  of date.
  """
  def handle_in("list_stations", %{"checksum" => checksum}, socket) do
    # verify checksum
    handle_in("list_stations", nil, socket)
  end
  def handle_in("list_stations", _msg, socket) do
    case PandoraPlayer.list_stations do
      {:ok, stations, checksum} -> broadcast!(socket, "list_stations", %{checksum: checksum, stations: Enum.map(stations, fn {name, index} -> %{name: name, index: index} end)})
      {:fail, reason} -> IO.puts(reason)
    end
    {:noreply, socket}
  end

  @doc """
  Sets the current station.
  """
  def handle_in("set_station", %{"index" => index}, socket) do
    {int_index, _rem} = Integer.parse(index)
    case PandoraPlayer.set_station(int_index) do
      :ok ->
        broadcast!(socket, "set_station", %{current_station: index})
        {:ok, now_playing} = PandoraPlayer.now_playing
        broadcast!(socket, "now_playing", %{now_playing: now_playing})
      {:fail, reason} ->
        IO.puts(reason)
    end
    {:noreply, socket}
  end


  def handle_out("list_stations", payload, socket) do
    push(socket, "list_stations", payload)
    {:noreply, socket}
  end

  def handle_out("set_stations", payload, socket) do
    push(socket, "set_stations", payload)
    {:noreply, socket}
  end

  def handle_out("now_playing", payload, socket) do
    push(socket, "now_playing", payload)
    {:noreply, socket}
  end
end
