defmodule AudioStreamer do
  use GenServer

  ### Client ###

  def start(url, opts \\ []) do
    GenServer.start(__MODULE__, {:ok, url}, opts)
  end

  ### Server ###

  def init({:ok, url}) do
    file = File.open!("test.mp4", [:append])
    HTTPoison.start
    %{:id => id} = HTTPoison.get!(url, %{"Accept" => "audio/mpeg"}, [stream_to: self, recv_timeout: :infinity])
    {:ok, %{id: id, file: file}}
  end

  def handle_info(%{:__struct__ => HTTPoison.AsyncStatus, :id => msg_id}, %{:id => stream_id} = state) when stream_id === msg_id, do: {:noreply, state}
  def handle_info(%{:__struct__ => HTTPoison.AsyncHeaders, :id => msg_id}, %{:id => stream_id} = state) when stream_id === msg_id, do: {:noreply, state}
  def handle_info(%{:__struct__ => HTTPoison.AsyncEnd, :id => msg_id}, %{:id => stream_id} = state) when stream_id === msg_id, do: {:stop, :end_of_stream, state}
  def handle_info(%{:__struct__ => HTTPoison.AsyncChunk, :chunk => chunk, :id => msg_id}, %{:id => stream_id, :file => file} = state) when stream_id === msg_id do
    IO.binwrite(file, chunk)
    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}

  def terminate(:end_of_stream, %{:file => file}), do: File.close(file)
  def terminate(_reason, _state), do: nil
end
