defmodule Pandora.ApiClient do
	use HTTPoison.Base
	alias Pandora.Crypto

@endpoint ~s(tuner.pandora.com/services/json/?method=)

	def process_url(url) do
		full_url(url)
	end

	defp full_url(method = "test.checkLicensing" <> params), do: "http://" <> @endpoint <> method <> params
	defp full_url(method = "auth.partnerLogin" <> params), do: "https://" <> @endpoint <> method <> params
	defp full_url(method = "auth.userLogin" <> params), do: "https://" <> @endpoint <> method <> params
	defp full_url(method = "user.getStationList" <> params), do: "http://" <> @endpoint <> method <> params
	defp full_url(method = "station.getPlaylist" <> params), do: "http://" <> @endpoint <> method <> params
	defp full_url(method = "station.addFeedback" <> params), do: "http://" <> @endpoint <> method <> params


	def process_response_body(body) do
		json = body |> Poison.decode!
		case json["stat"] do
			"fail" -> {json["message"], json["code"]} # TODO: Add function to convert error code to message
			"ok" -> json["result"]
		end
	end

	def check_licensing() do
		response = get!("test.checkLicensing")
		response.body
	end

	def partner_login() do
		body = %{"username" => "android", 
			"password" => "AC7IBG09A3DTSYM4R41UJWL07VLN8JI7", 
			"deviceModel" => "android-generic", 
			"version" => "5", 
			"includeUrls" => false} |> Poison.encode!

		response = post!("auth.partnerLogin", body)

		case Crypto.decrypt_sync_time(response.body["syncTime"]) do
			{:ok, syncTime} -> 
				%{partnerAuthToken: response.body["partnerAuthToken"],
				partnerId: response.body["partnerId"], 
				syncTime: syncTime,
				timeSynced: :os.system_time(:seconds)}
			{:error, _} -> {:error, "Error decrypting syncTime."}
		end
	end

	@spec user_login(String.t, String.t, String.t, String.t, integer) :: {atom, %{}} | {atom, tuple}
	def user_login(username, password, partnerAuthToken, partnerId, syncTime) do
		body = %{"loginType" => "user", 
			"username" => username, 
			"password" => password, 
			"partnerAuthToken" => partnerAuthToken, 
			"syncTime" => syncTime} |> Poison.encode! |> Crypto.encrypt_body

		query = URI.encode_query([
			{"partner_id", partnerId}, 
			{"auth_token", URI.encode(partnerAuthToken)}])

		response = post!("auth.userLogin&" <> query, body)

		case response.body do
			user when is_map(user) -> {:ok, %{userAuthToken: user["userAuthToken"], userId: user["userId"], canListen: user["canListen"]}}
			error when is_tuple(error) -> {:fail, error}
		end
	end

	@spec get_station_list(String.t, String.t, String.t, integer, integer) :: %{}
	def get_station_list(partnerId, userAuthToken, userId, syncTime, timeSynced) do
		body = %{"includeStationArtUrl" => true,
			"userAuthToken" => userAuthToken,
			"syncTime" => adjusted_sync_time(syncTime, timeSynced)} |> Poison.encode! |> Crypto.encrypt_body

		query = URI.encode_query([
			{"partner_id", partnerId}, 
			{"auth_token", URI.encode(userAuthToken)}, 
			{"user_id", userId}])

		response = post!("user.getStationList&" <> query, body)

		%{checksum: response.body["checksum"],
		stations: response.body["stations"]}
	end

	@spec get_playlist(String.t, String.t, String.t, String.t, integer, integer) :: [%{}]
	def get_playlist(stationToken, partnerId, userAuthToken, userId, syncTime, timeSynced) do
		body = %{"userAuthToken" => userAuthToken,
			"syncTime" => adjusted_sync_time(syncTime, timeSynced),
			"stationToken" => stationToken} |> Poison.encode! |> Crypto.encrypt_body

		query = URI.encode_query([
			{"partner_id", partnerId}, 
			{"auth_token", URI.encode(userAuthToken)}, 
			{"user_id", userId}])

		response = post!("station.getPlaylist&" <> query, body)

		Enum.filter(response.body["items"], &Map.has_key?(&1, "songName"))
	end

	@spec add_feedback(String.t, String.t, boolean, String.t, String.t, String.t, integer, integer) :: %{}
	def add_feedback(stationToken, trackToken, isPositive, partnerId, userAuthToken, userId, syncTime, timeSynced) do
		body = %{"userAuthToken" => userAuthToken,
			"syncTime" => adjusted_sync_time(syncTime, timeSynced),
			"stationToken" => stationToken,
			"trackToken" => trackToken,
			"isPositive" => isPositive} |> Poison.encode! |> Crypto.encrypt_body

		query = URI.encode_query([
			{"partner_id", partnerId}, 
			{"auth_token", URI.encode(userAuthToken)}, 
			{"user_id", userId}])

		response = post!("station.addFeedback&" <> query, body)
		response.body
	end

	defp adjusted_sync_time(syncTime, timeSynced), do: syncTime + (:os.system_time(:seconds) - timeSynced)
end