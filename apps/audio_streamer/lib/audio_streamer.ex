defmodule AudioStreamer do

  ## Client

  def stream_url(url) do
    Task.start_link(fn -> init(url) end)
  end

  def pause(task) do
    send(task, :pause)
  end

  def kill(task) do
    send(task, :kill)
  end

  ## Task

  def init(url) do
    file = File.open!("test.mp4", [:append])
    %{id: stream_id} = HTTPoison.get!(url, %{"Accept" => "audio/mpeg"}, [stream_to: self, recv_timeout: :infinity])
    loop(%{stream_id: stream_id, file: file, paused: false})
  end

  defp loop(%{stream_id: stream_id, file: file, paused: paused} = state) do
    receive do
      %HTTPoison.AsyncStatus{code: 200, id: ^stream_id} -> loop(state)
      %HTTPoison.AsyncHeaders{id: ^stream_id} -> loop(state)
      %HTTPoison.AsyncChunk{id: ^stream_id, chunk: chunk} -> 
        IO.binwrite(file, chunk)
        loop(state)
      %HTTPoison.AsyncEnd{id: ^stream_id} -> terminate(file)
      :pause -> loop(%{state | paused: not paused})
      :kill -> terminate(file)
      _ -> loop(state)
    end
    
  end

  defp terminate(file) do
    File.close(file)
    Process.exit(self(), :normal)
  end
end
