defmodule PandoraPhoenix.PlayerView do
  use PandoraPhoenix.Web, :view

  def song_name(%{"songName" => song}), do: song
  def song_name(nil), do: nil

  def artist_name(%{"artistName" => artist}), do: artist
  def artist_name(nil), do: nil

  def album_name(%{"albumName" => album}), do: album
  def album_name(nil), do: nil

  def song_url_high(%{"audioUrlMap" => %{"highQuality" => %{"audioUrl" => url}}}), do: url

  def song_url_med(%{"audioUrlMap" => %{"mediumQuality" => %{"audioUrl" => url}}}), do: url

  def song_url_low(%{"audioUrlMap" => %{"lowQuality" => %{"audioUrl" => url}}}), do: url

  def song_lyrics(nil), do: "No song playing."
  def song_lyrics(%{"songName" => song, "artistName" => artist}) do
    "Lyrics not implemented yet."
    url = URI.encode("http://lyrics.wikia.com/api.php?action=lyrics&song=#{song}&artist=#{artist}&fmt=json")
    %{body: body} = HTTPoison.get!(url)
    body
    |> get_link
    |> get_lyrics
  end

  defp get_link("song = " <> json) do
    json
    |> String.replace("'", "\"")
    |> Poison.decode!
    |> Map.fetch!("url")
    |> URI.encode
  end
  defp get_link(_), do: {:fail, "Unable to find lyrics :("}

  defp get_lyrics({:fail, reason}), do: reason
  defp get_lyrics(url) do
    %{body: html} = HTTPoison.get!(url, [], [follow_redirect: true])
    regex = ~r/<script>.*<\/script>/
    raw_html = html |> Floki.find(".lyricbox") |> Floki.raw_html
    Regex.replace(regex, raw_html, "")
  end

end
