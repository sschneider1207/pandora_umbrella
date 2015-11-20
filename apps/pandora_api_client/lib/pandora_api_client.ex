defmodule PandoraApiClient do
  use HTTPoison.Base
  alias PandoraApiClient.Crypto

@endpoint ~s(tuner.pandora.com/services/json/?method=)

  
  def process_url(url) do
    protocol(url) <> @endpoint  <> url
  end

  defp protocol("test.checkLicensing" <> _), do: "http://"
  defp protocol("auth.partnerLogin" <> _), do: "https://"
  defp protocol("auth.userLogin" <> _), do: "https://"
  defp protocol("user.getStationList" <> _), do: "http://"
  defp protocol("station.getPlaylist" <> _), do: "http://"
  defp protocol("station.addFeedback" <> _), do: "http://"


  def process_response_body(body) do
    json = body |> Poison.decode!
    case json["stat"] do
      "fail" -> {json["message"], json["code"]} # TODO: Add function to convert error code to message
      "ok" -> json["result"]
    end
  end

  def check_licensing do
    response = get!("test.checkLicensing")
    response.body
  end

  def partner_login do
    body = %{"username" => "android", 
      "password" => "AC7IBG09A3DTSYM4R41UJWL07VLN8JI7", 
      "deviceModel" => "android-generic", 
      "version" => "5", 
      "includeUrls" => false} |> Poison.encode!

    response = post!("auth.partnerLogin", body)

    case Crypto.decrypt_sync_time(response.body["syncTime"]) do
      {:ok, sync_time} -> 
        %{partner_auth_token: response.body["partnerAuthToken"],
        partner_id: response.body["partnerId"], 
        sync_time: sync_time,
        time_synced: :os.system_time(:seconds)}
      {:error, _} -> {:error, "Error decrypting syncTime."}
    end
  end

  @spec user_login(String.t, String.t, String.t, String.t, integer) :: {atom, %{}} | {atom, tuple}
  def user_login(username, password, partner_auth_token, partner_id, sync_time) do
    body = %{"loginType" => "user", 
      "username" => username, 
      "password" => password, 
      "partnerAuthToken" => partner_auth_token, 
      "syncTime" => sync_time} |> Poison.encode! |> Crypto.encrypt_body

    query = URI.encode_query([
      {"partner_id", partner_id}, 
      {"auth_token", URI.encode(partner_auth_token)}])

    response = post!("auth.userLogin&" <> query, body)

    case response.body do
      user when is_map(user) -> {:ok, %{user_auth_token: user["userAuthToken"], user_id: user["userId"], can_listen: user["canListen"]}}
      error when is_tuple(error) -> {:fail, error}
    end
  end

  @spec get_station_list(String.t, String.t, String.t, integer, integer) :: %{}
  def get_station_list(partner_id, user_auth_token, user_id, sync_time, time_synced) do
    body = %{"includeStationArtUrl" => true,
      "userAuthToken" => user_auth_token,
      "syncTime" => adjusted_sync_time(sync_time, time_synced)} |> Poison.encode! |> Crypto.encrypt_body

    query = URI.encode_query([
      {"partner_id", partner_id}, 
      {"auth_token", URI.encode(user_auth_token)}, 
      {"user_id", user_id}])

    response = post!("user.getStationList&" <> query, body)

    %{checksum: response.body["checksum"],
    stations: response.body["stations"]}
  end

  @spec get_playlist(String.t, String.t, String.t, String.t, integer, integer) :: [%{}]
  def get_playlist(station_token, partner_id, user_auth_token, user_id, sync_time, time_synced) do
    body = %{"userAuthToken" => user_auth_token,
      "syncTime" => adjusted_sync_time(sync_time, time_synced),
      "stationToken" => station_token} |> Poison.encode! |> Crypto.encrypt_body

    query = URI.encode_query([
      {"partner_id", partner_id}, 
      {"auth_token", URI.encode(user_auth_token)}, 
      {"user_id", user_id}])

    response = post!("station.getPlaylist&" <> query, body)

    Enum.filter(response.body["items"], &Map.has_key?(&1, "songName"))
  end

  @spec add_feedback(String.t, String.t, boolean, String.t, String.t, String.t, integer, integer) :: %{}
  def add_feedback(station_token, track_oken, is_positive, partner_id, user_auth_token, user_id, sync_time, time_synced) do
    body = %{"userAuthToken" => user_auth_token,
      "syncTime" => adjusted_sync_time(sync_time, time_synced),
      "stationToken" => station_token,
      "trackToken" => track_oken,
      "isPositive" => is_positive} |> Poison.encode! |> Crypto.encrypt_body

    query = URI.encode_query([
      {"partner_id", partner_id}, 
      {"auth_token", URI.encode(user_auth_token)}, 
      {"user_id", user_id}])

    response = post!("station.addFeedback&" <> query, body)
    response.body
  end

  defp adjusted_sync_time(sync_time, time_synced), do: sync_time + (:os.system_time(:seconds) - time_synced)
end
