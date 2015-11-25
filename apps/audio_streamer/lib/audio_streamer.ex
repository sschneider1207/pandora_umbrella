defmodule AudioStreamer do

  ## Client

  def stream_url(url) do
    {:ok, pid} = Task.start_link(fn -> init(url) end)
    {pid, Process.monitor(pid)}
  end

  def pause(task) do
    send(task, :pause)
  end

  def kill(task) do
    send(task, :kill)
  end

  ## Task

  def init(url) do
    %{id: stream_id} = HTTPoison.get!(url, %{"Accept" => "audio/mpeg"}, [stream_to: self, recv_timeout: :infinity])
    loop(%{stream_id: stream_id, paused: false})
  end

  defp inf, do: inf

  defp loop(%{stream_id: stream_id, paused: paused} = state) do
    receive do
      %HTTPoison.AsyncStatus{code: 200, id: ^stream_id} -> loop(state)
      %HTTPoison.AsyncHeaders{id: ^stream_id} -> loop(state)
      %HTTPoison.AsyncChunk{id: ^stream_id, chunk: chunk} ->
        loop(state)
      %HTTPoison.AsyncEnd{id: ^stream_id} -> loop(state)
      :pause -> loop(%{state | paused: not paused})
      :kill -> terminate()
      msg -> IO.inspect(msg); loop(state)
    end
  end

  defp terminate() do
    Process.exit(self(), :normal)
  end
end
