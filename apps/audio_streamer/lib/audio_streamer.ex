defmodule AudioStreamer do

@py_script ~S(E:\git\pandora_umbrella\priv_dir\elixir_port_audio.py)

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
    IO.puts("Opening port")
    port = Port.open({:spawn, "python \"#{@py_script}\""}, [:binary]) 
    %{id: stream_id} = HTTPoison.get!(url, %{"Accept" => "audio/mpeg"}, [stream_to: self, recv_timeout: :infinity])
    loop(%{stream_id: stream_id, port: port, paused: false})
  end

  defp inf, do: inf

  defp loop(%{stream_id: stream_id, port: port, paused: paused} = state) do
    receive do
      %HTTPoison.AsyncStatus{code: 200, id: ^stream_id} -> loop(state)
      %HTTPoison.AsyncHeaders{id: ^stream_id} -> loop(state)
      %HTTPoison.AsyncChunk{id: ^stream_id, chunk: chunk} ->
        Port.command(port, chunk)
        loop(state)
      %HTTPoison.AsyncEnd{id: ^stream_id} -> IO.puts("end"); inf
      :pause -> loop(%{state | paused: not paused})
      :kill -> terminate()
      {^port, {:data, result}} -> IO.inspect(result); loop(state)
      msg -> IO.inspect(msg); loop(state)
    end    
  end

  defp terminate() do
    Process.exit(self(), :normal)
  end
end
