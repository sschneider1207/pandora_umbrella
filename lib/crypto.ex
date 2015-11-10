defmodule Pandora.Crypto do

@decrypt_key ~s(R=U!LH$O2B#)
@encrypt_key ~s(6#26FRL$ZWD)


	def decrypt_synctime(syncTime) do
		decodedSyncTime = syncTime |> Hexate.decode
		<<_, _, _, _, a, b, c, d, _ :: binary>> = :crypto.blowfish_ecb_decrypt(@decrypt_key, decodedSyncTime)
		<<a, b, c, d>>
	end

	def encrypt_body(body) do
		:crypto.blowfish_ecb_encrypt(@encrypt_key, body)
	end
end