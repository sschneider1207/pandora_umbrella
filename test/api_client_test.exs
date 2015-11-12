defmodule Pandora.ApiClientTest do
	use ExUnit.Case, async: true
	
@username ~s(sds6065@gmail.com)
@password ~s(ginger)

	setup do
		Pandora.ApiClient.start
	end

	test "testing api flow" do
		partnerResp = Pandora.ApiClient.partner_login
		userResp = Pandora.ApiClient.user_login(@username, @password, partnerResp.partnerAuthToken, partnerResp.partnerId, partnerResp.syncTime)
	end
end