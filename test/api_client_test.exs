defmodule Pandora.ApiClientTest do
	use ExUnit.Case, async: true
	
@username ~s(sds6065@gmail.com)
@password ~s(ginger)

	setup do
		Pandora.ApiClient.start
	end

	test "testing api flow" do
		partnerResp = Pandora.ApiClient.partner_login
		userResp = Pandora.ApiClient.user_login(username, password, partnerResp.partnerAuthToken, partnerResp.partnerId, partnerResp.syncTime)
		stationResp = Pandora.ApiClient.get_station_list(partnerResp.partnerId, userResp.userAuthToken, userResp.userId, partnerResp.syncTime, partnerResp.timeSynced)
		station = hd stationResp.stations
		playlist = Pandora.ApiClient.get_playlist(station["stationToken"], partnerResp.partnerId, userResp.userAuthToken, userResp.userId, partnerResp.syncTime, partnerResp.timeSynced)
		IO.inspect(stationResp)
	end
end