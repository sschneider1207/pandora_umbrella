defmodule Pandora.Player do  
  use GenServer
  alias Pandora.ApiClient

  ### Client ###

  def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, :ok, opts)
  end

  def login(server, username, password) do
    GenServer.call(server, {:login, {username, password}})
  end

  def logout(server) do
    GenServer.call(server, :logout)
  end

  def list_stations(server) do
    GenServer.call(server, :get_stations)
  end

  def set_station(server, station_index) do
    GenServer.call(server, {:set_station, station_index})
  end

  def current_station(server) do
    GenServer.call(server, :get_station)
  end

  ### Server ###

  def init(:ok) do
    ApiClient.start
    %{:partner_auth_token => partner_auth_token, :partner_id => partner_id, :sync_time => sync_time, :time_synced => time_synced} = ApiClient.partner_login
    {:ok, %{partner_auth_token: partner_auth_token, partner_id: partner_id, sync_time: sync_time, time_synced: time_synced, user_auth_token: nil, user_id: nil, username: nil, password: nil, stations: [], current_station: nil, playlist: [], current_song: nil}}
  end

  @doc """
  Callback for login/3.
  """
  def handle_call({:login, _user}, _from, %{:username => username} = state) when byte_size(username) > 0, do: {:reply, {:fail, "Already logged in as #{username}.  Please log out first."}, state}
  def handle_call({:login, {username, password}}, _from, %{:partner_auth_token => partner_auth_token, :partner_id => partner_id, :sync_time => sync_time} = state) do
    case ApiClient.user_login(username, password, partner_auth_token, partner_id, sync_time) do
      {:fail, _error} -> {:reply, {:fail, "Incorrect username/password."}, state}
      {:ok, %{:can_listen => can_listen, :user_auth_token => user_auth_token, :user_id => user_id}} ->
        if can_listen do
          {:reply, :ok, %{state | :user_auth_token => user_auth_token, :user_id => user_id, :username => username, :password => password}}
        else
          {:reply, {:fail, "User cannot listen."}, state}
        end
    end
  end

  @doc """
  Callback for logout/1.
  """
  def handle_call(:logout, _from, %{:user_auth_token => nil} = state), do: {:reply, {:fail, "Not logged in."}, state}
  def handle_call(:logout, _from, state), do: {:reply, :ok, %{state | :user_auth_token => nil, :user_id => nil, :username => nil, :password => nil, :stations => [], :current_station => nil, :playlist => [], :current_song => nil}}

  @doc """
  Callback for list_stations/1.
  Caches station list.
  """  
  def handle_call(:get_stations, _from, %{:user_auth_token => nil} = state), do: {:reply, {:fail, "Not logged in."}, state}
  def handle_call(:get_stations, _from, %{:stations => stations} = state) when stations !== [], do: {:reply, {:ok, Enum.map(stations, &Map.fetch!(&1, "stationName")) |> Enum.with_index}, state}
  def handle_call(:get_stations, _from, %{:partner_id => partner_id, :user_auth_token => user_auth_token, :user_id => user_id, :sync_time => sync_time, :time_synced => time_synced} = state) do
    %{:stations => stations} = ApiClient.get_station_list(partner_id, user_auth_token, user_id, sync_time, time_synced)
    {:reply, {:ok, Enum.map(stations, &Map.fetch!(&1, "stationName")) |> Enum.with_index}, %{state | :stations => stations}}
  end

  @doc """
  Callback for set_station/2.
  If station list hasn't been cached yet, will get it now.
  """
  def handle_call({:set_station, _station_index}, _from, %{:user_auth_token => nil} = state), do: {:reply, {:fail, "Not logged in."}, state}
  def handle_call({:set_station, station_index}, _from, %{:stations => stations} = state) when stations !== [], do: handle_set_station(station_index, state)
  def handle_call({:set_station, station_index}, _from, %{:partner_id => partner_id, :user_auth_token => user_auth_token, :user_id => user_id, :sync_time => sync_time, :time_synced => time_synced} = state) do
    %{:stations => stations} = ApiClient.get_station_list(partner_id, user_auth_token, user_id, sync_time, time_synced)
    handle_set_station(station_index, %{state | :stations => stations})
  end

  @doc """
  Callback for current_station/1.
  """
  def handle_call(:get_station, _from, %{:current_station => current_station} = state) when current_station === nil, do: {:reply, {:fail, "No station currently selected."}, state}
  def handle_call(:get_station, _from, %{:current_station => current_station, :stations => stations} = state) do 
    case Enum.find(stations, nil, &station_token_match?(&1, current_station)) do
      nil -> {:reply, {:fail, "Error getting station."}, state}
      station -> {:reply, {:ok, station["stationName"]}, state}
    end
  end

  ### Private helpers ###

  defp handle_set_station(station_index, %{:stations => stations} = state) do
    case Enum.fetch(stations, station_index) do
      :error -> {:reply, {:fail, "Station index out of range."}, state}
      {:ok, %{"stationToken" => station_token}} -> {:reply, :ok, %{state | :current_station => station_token}}        
    end
  end

  defp station_token_match?(station, station_token), do: station["stationToken"] === station_token
end