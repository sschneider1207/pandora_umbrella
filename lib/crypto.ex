defmodule Pandora.Crypto do

@decrypt_key ~s(R=U!LH$O2B#)
@encrypt_key ~s(6#26FRL$ZWD)


	@doc ~S"""
	Decrypts the sync time returned by the Pandora api.
	Result is a unix timestamp.

	## Examples

	    iex> Pandora.Crypto.decrypt_sync_time("9b5c019b19035fcbe5aaa601776d491c")
	    {:ok, 1447198097}

	If your input is not a 32 bit bitstring, an error will be returned:

	    iex> Pandora.Crypto.decrypt_sync_time("too short")
	    {:error, "syncTime must be a 32 bit bitstring."}
	"""
	@spec decrypt_sync_time(<<_ :: 32>>) :: {atom, integer}
	def decrypt_sync_time(syncTime) when byte_size(syncTime) == 32 do 
		<<firstHalf :: size(64), secondHalf :: size(64)>> = Hexate.decode(syncTime)
		<<_ :: size(32), decryptedFirstHalf :: size(32), _ :: binary>> = :crypto.blowfish_ecb_decrypt(@decrypt_key, <<firstHalf :: size(64)>>)
		<<decryptedSecondHalf :: size(64), _ :: binary>> = :crypto.blowfish_ecb_decrypt(@decrypt_key, <<secondHalf :: size(64)>>)
		{decrypted, _} = <<decryptedFirstHalf :: size(32), decryptedSecondHalf :: size(64)>> |> Integer.parse
		{:ok, decrypted}
	end

	@spec decrypt_sync_time(any) :: {atom, String.t}
	def decrypt_sync_time(_), do: {:error, "syncTime must be a 32 bit bitstring."}


	@doc ~S"""
	Encrypts a UTF-8 encoded bitstring with the Pandora blowfish encrypt key.

	## Example

	    iex> Pandora.Crypto.encrypt_body("1234567812345678")
	    "c0987ab91d507e5dc0987ab91d507e5d"
	"""
	@spec encrypt_body(String.t) :: String.t
	def encrypt_body(body) when is_bitstring(body) do		
		body 
		|> chunk_body
		|> Enum.map(&encrypt_chunk/1)
		|> List.foldl(<<>>, &fold_encrypted_chunk/2)
		|> Hexate.encode
	end	

	defp chunk_body(body) when byte_size(body) >= 8 do
		{chunk, remaining} = String.split_at(body, 8)		
		[chunk | chunk_body(remaining)]
	end
	defp chunk_body(body) when byte_size(body) > 0, do: [String.ljust(body, 8)]
	defp chunk_body(body) when byte_size(body) == 0, do: []

	defp encrypt_chunk(chunk) do
		<<encryptedBytes :: size(64), _ ::binary>> = :crypto.blowfish_ecb_encrypt(@encrypt_key, chunk)
		encryptedBytes
	end

	defp fold_encrypted_chunk(chunk, acc), do: acc <> <<chunk :: size(64)>>
end