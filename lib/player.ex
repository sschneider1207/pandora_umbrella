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

  	def list_stations(server) do
  		GenServer.call(server, :stations)
  	end

  	def get_playlist(server, stationToken) do
  		GenServer.call(server, {:playlist, stationToken})
  	end

  	### Server ###

  	def init(:ok) do
  		ApiClient.start
  		%{:partnerAuthToken => partnerAuthToken, :partnerId => partnerId, :syncTime => syncTime, :timeSynced => timeSynced} = ApiClient.partner_login
  		{:ok, %{partnerAuthToken: partnerAuthToken, partnerId: partnerId, syncTime: syncTime, timeSynced: timeSynced, userAuthToken: nil, userId: nil, stations: []}}
  	end

  	@doc """
  	Callback for login/3.
  	"""
  	def handle_call({:login, {username, password}}, _from, %{:partnerAuthToken => partnerAuthToken, :partnerId => partnerId, :syncTime => syncTime} = state) do
  		ApiClient.user_login(username, password, partnerAuthToken, partnerId, syncTime) |> handle_login_response(state)
  	end

  	@doc """
  	Callback for list_stations/1.
  	Caches station list for future requests.
  	"""	
  	def handle_call(:stations, _from, %{:userAuthToken => nil} = state), do: {:reply, {:fail, "Not logged in."}, state}
  	def handle_call(:stations, _from, %{:stations => stations} = state) when stations !== [], do: {:reply, {:ok, stations}, state}
  	def handle_call(:stations, _from, %{:partnerId => partnerId, :userAuthToken => userAuthToken, :userId => userId, :syncTime => syncTime, :timeSynced => timeSynced} = state) do
  		%{:stations => stations} = Pandora.ApiClient.get_station_list(partnerId, userAuthToken, userId, syncTime, timeSynced)
  		{:reply, {:ok, stations}, %{state | :stations => stations}}
  	end

  	@doc """
  	Callback for get_playlist/1.
  	If station list is currently cached, will verify that the given station token exists first.
  	"""
  	def handle_call({:playlist, _stationToken}, _from, %{:userAuthToken => nil} = state), do: {:reply, {:fail, "Not logged in."}, state}
  	def handle_call({:playlist, stationToken}, _from, %{:stations => stations, :partnerId => partnerId, :userAuthToken => userAuthToken, :userId => userId, :syncTime => syncTime, :timeSynced => timeSynced} = state) when stations !== [] do
  		if Enum.any?(stations, fn station -> station["stationToken"] === stationToken end) do
  			playlist = Pandora.ApiClient.get_playlist(stationToken, partnerId, userAuthToken, userId, syncTime, timeSynced)
  			{:reply, {:ok, playlist}, state}
  		else
  			{:reply, {:fail, "Station token not found."}, state}
  		end
  	end
  	def handle_call({:playlist, stationToken}, _from, %{:partnerId => partnerId, :userAuthToken => userAuthToken, :userId => userId, :syncTime => syncTime, :timeSynced => timeSynced} = state) do
  		playlist = Pandora.ApiClient.get_playlist(stationToken, partnerId, userAuthToken, userId, syncTime, timeSynced)
  		{:reply, {:ok, playlist}, state}
  	end

	defp handle_login_response({:fail, _error}, state), do: {:reply, :fail, state}
  	defp handle_login_response({:ok, %{:canListen => canListen, :userAuthToken => userAuthToken, :userId => userId}}, state) do
  		if canListen do
  			{:reply, :ok, %{state | :userAuthToken => userAuthToken, :userId => userId}}
  		else
  			{:reply, :fail, state}
  		end
  	end
end