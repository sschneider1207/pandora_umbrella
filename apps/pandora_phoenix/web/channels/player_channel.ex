defmodule PandoraPhoenix.PlayerChannel do
  use Phoenix.Channel

  def join("player", _msg, socket) do
    {:ok, socket}
  end

  def handle_in("list_stations", %{"checksum" => checksum}, socket) do
    # verify checksum
    handle_in("list_stations", nil, socket)
  end
  def handle_in("list_stations", _msg, socket) do
    case PandoraPlayer.list_stations do
      {:ok, stations} -> broadcast!(socket, "list_stations", %{checksum: "checksum123", stations: Enum.map(stations, fn {name, index} -> %{name: name, index: index} end)})
      {:fail, reason} -> IO.puts(reason)
    end
    {:noreply, socket}
  end



  def handle_out("list_stations", payload, socket) do
    push(socket, "list_stations", payload)
    {:noreply, socket}
  end
end
