defmodule PandoraPhoenix.PlayerChannel do
  use Phoenix.Channel

  def join("player", _msg, socket) do
    {:ok, socket}
  end

  def handle_in("stations", %{"checksum" => nil}, socket) do
    # get station list
    broadcast!(socket, "stations", %{checksum: "checksum123", stations: ["1", "2", "3"]})
    {:noreply, socket}
  end
  def handle_in("stations", %{"checksum" => checksum}, socket) do
    # verify checksum
    handle_in("stations", %{"checksum" => nil}, socket)
  end


  def handle_out("stations", payload, socket) do
    push(socket, "stations", payload)
    {:noreply, socket}
  end
end
