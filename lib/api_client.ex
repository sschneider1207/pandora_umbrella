defmodule Pandora.ApiClient do
	use HTTPoison.Base
	alias Pandora.Crypto

	def process_url(url) do
		case url do
			"test.checkLicensing" <> _ -> protocol = "http://"
			"auth.partnerLogin" <> _ -> protocol = "https://"
			"auth.userLogin" <> _ -> protocol = "https://"
		end
		protocol <> "tuner.pandora.com/services/json/?method=" <> url
	end

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
		body = %{
			"username" => "android", 
			"password" => "AC7IBG09A3DTSYM4R41UJWL07VLN8JI7", 
			"deviceModel" => "android-generic", 
			"version" => "5", 
			"includeUrls" => false} 
			|> Poison.encode!

		response = post!("auth.partnerLogin", body)

		case Crypto.decrypt_sync_time(response.body["syncTime"]) do
			{:ok, syncTime} -> 
				%{partnerAuthToken: response.body["partnerAuthToken"],
				partnerId: response.body["partnerId"], 
				syncTime: syncTime}
			{:error, _} -> {:error, "Error decrypting syncTime."}
		end
	end

	def user_login(username, password, partnerAuthToken, partnerId, syncTime) do
		body = %{
			"loginType" => "user", 
			"username" => username, 
			"password" => password, 
			"partnerAuthToken" => partnerAuthToken, 
			"syncTime" => syncTime}
			|> Poison.encode!
			|> Crypto.encrypt_body

		query = URI.encode_query([{"partner_id", partnerId}, {"auth_token", URI.encode(partnerAuthToken)}])

		response = post!("auth.userLogin&" <> query, body)

		%{userAuthToken: response.body["userAuthToken"],
		userId: response.body["userId"],
		canListen: response.body["canListen"]}
	end
end