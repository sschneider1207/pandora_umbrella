defmodule PandoraPlayer do
  use GenServer
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(PandoraPlayer, [[name: __MODULE__]]),
      worker(GenEvent, [[name: PandoraPlayer.EventManager]])
    ]

    opts = [strategy: :one_for_one, name: PandoraPlayer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  ### Client ###

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def login(username, password) do
    GenServer.call(__MODULE__, {:login, {username, password}})
  end

  def logout do
    GenServer.call(__MODULE__, :logout)
  end

  def list_stations do
    GenServer.call(__MODULE__, :get_stations)
  end

  def set_station(station_index) do
    GenServer.call(__MODULE__, {:set_station, station_index})
  end

  def current_station do
    GenServer.call(__MODULE__, :current_station)
  end

  def now_playing do
    GenServer.call(__MODULE__, :now_playing)
  end

  ### Server ###

  def init(:ok) do
    {partner_auth_token, partner_id, sync_time, time_synced} = PandoraApiClient.partner_login
    {:ok, %{partner_auth_token: partner_auth_token, partner_id: partner_id, sync_time: sync_time, time_synced: time_synced, user_auth_token: nil, user_id: nil, username: nil, password: nil, stations: [], checksum: nil, current_station: nil, playlist: [], now_playing: nil}}
  end

  @doc """
  Callback for login/3.
  """
  def handle_call({:login, _user}, _from, %{username: username} = state) when byte_size(username) > 0, do: {:reply, {:fail, "Already logged in as #{username}.  Please log out first."}, state}
  def handle_call({:login, {username, password} = user}, _from, %{partner_auth_token: partner_auth_token, partner_id: partner_id, sync_time: sync_time} = state) do
    PandoraApiClient.user_login(username, password, partner_auth_token, partner_id, sync_time)
    |> login_reply(user, state)
  end

  @doc """
  Callback for logout/1.
  """
  def handle_call(:logout, _from, %{user_auth_token: nil} = state), do: {:reply, {:fail, "Not logged in."}, state}
  def handle_call(:logout, _from, state), do: {:reply, :ok, %{state | user_auth_token: nil, user_id: nil, username: nil, password: nil, stations: [], current_station: nil, playlist: [], now_playing: nil}}

  @doc """
  Callback for list_stations/1.
  Caches station list.
  """
  def handle_call(:get_stations, _from, %{user_auth_token: nil} = state), do: {:reply, {:fail, "Not logged in."}, state}
  def handle_call(:get_stations, _from, %{stations: stations, checksum: checksum} = state) when stations !== [] do
    {:reply, {:ok, get_stations_with_index(stations), checksum}, state}
  end
  def handle_call(:get_stations, _from, %{partner_id: partner_id, user_auth_token: user_auth_token, user_id: user_id, sync_time: sync_time, time_synced: time_synced} = state) do
    {stations, checksum} = PandoraApiClient.get_station_list(partner_id, user_auth_token, user_id, sync_time, time_synced)
    {:reply, {:ok, get_stations_with_index(stations), checksum}, %{state | stations: stations, checksum: checksum}}
  end

  @doc """
  Callback for set_station/2.
  If station list hasn't been cached yet, will get it now.
  """
  def handle_call({:set_station, _station_index}, _from, %{user_auth_token: nil} = state), do: {:reply, {:fail, "Not logged in."}, state}
  def handle_call({:set_station, station_index}, _from, %{stations: stations} = state) when stations !== [] do
   Enum.fetch(stations, station_index)
   |> set_station_reply(%{state | stations: stations})
 end
  def handle_call({:set_station, station_index}, _from, %{partner_id: partner_id, user_auth_token: user_auth_token, user_id: user_id, sync_time: sync_time, time_synced: time_synced} = state) do
    {stations, _checksum} = PandoraApiClient.get_station_list(partner_id, user_auth_token, user_id, sync_time, time_synced)
    Enum.fetch(stations, station_index)
    |> set_station_reply(%{state | stations: stations})
  end

  @doc """
  Callback for current_station/1.
  """
  def handle_call(:current_station, _from, %{user_auth_token: nil} = state), do: {:reply, {:fail, "Not logged in."}, state}
  def handle_call(:current_station, _from, %{current_station: nil} = state), do: {:reply, {:fail, "No station currently selected."}, state}
  def handle_call(:current_station, _from, %{current_station: current_station, stations: stations} = state) do
   Enum.find(stations, nil, &station_token_match?(&1, current_station))
   |> current_station_reply(state)
  end

  @doc """
  Callback for now_playing/1.
  """
  def handle_call(:now_playing, _from, %{user_auth_token: nil} = state), do: {:reply, {:fail, "Not logged in."}, state}
  def handle_call(:now_playing, _from, %{current_station: nil} = state), do: {:reply, {:fail, "No station currently selected."}, state}
  def handle_call(:now_playing, _from, %{now_playing: %{"songName" => song, "artistName" => artist, "albumName" => album, "audioUrlMap" => audio_url_map}} = state), do: {:reply, {:ok, %{song: song, artist: artist, album: album, urls: audio_url_map}}, state}

  @doc """
  Callback for current song ending.
  """
  def handle_info({:DOWN, monitor_reference, :process, pid, _reason}, %{audio_streamer: audio_streamer, audio_streamer_monitor: audio_streamer_monitor} = state) when pid === audio_streamer and monitor_reference == audio_streamer_monitor, do: {:noreply, next_song(%{state | audio_streamer: nil, audio_streamer_monitor: nil})}

  ### Private helpers ###

  defp login_reply({:fail, _error}, _user, state), do: {:reply, {:fail, "Incorrect username/password."}, state}
  defp login_reply({:ok, {user_auth_token, user_id, can_listen}}, {username, password}, state) do
    if can_listen do
      {:reply, :ok, %{state | user_auth_token: user_auth_token, user_id: user_id, username: username, password: password}}
    else
      {:reply, {:fail, "User cannot listen."}, state}
    end
  end

  defp get_stations_with_index(stations) do
   Enum.map(stations, &Map.fetch!(&1, "stationName")) |> Enum.with_index
  end

  defp set_station_reply(:error, state), do: {:reply, {:fail, "Station index out of range."}, state}
  defp set_station_reply({:ok, %{"stationToken" => station_token}}, state), do: {:reply, :ok, next_song(%{state | current_station: station_token, now_playing: nil, playlist: []})}

  defp current_station_reply(nil, state), do: {:reply, {:fail, "Error getting station."}, state}
  defp current_station_reply(%{"stationName" => stationName}, state), do: {:reply, {:ok, stationName}, state}

  defp station_token_match?(station, station_token), do: station["stationToken"] === station_token

  defp next_song(%{partner_id: partner_id, user_auth_token: user_auth_token, user_id: user_id, sync_time: sync_time, time_synced: time_synced, current_station: current_station, playlist: []} = state) do
    [new_song | playlist] = PandoraApiClient.get_playlist(current_station, partner_id, user_auth_token, user_id, sync_time, time_synced)
    notify_new_song(new_song)
    %{state | now_playing: new_song, playlist: playlist}
  end
  defp next_song(%{playlist: [new_song | playlist]} = state) do
    notify_new_song(new_song)
    %{state | now_playing: new_song, playlist: playlist}
  end

  defp notify_new_song(%{"songName" => song, "artistName" => artist, "albumName" => album}), do: GenEvent.sync_notify(PandoraPlayer.EventManager, {song, artist, album})
end
