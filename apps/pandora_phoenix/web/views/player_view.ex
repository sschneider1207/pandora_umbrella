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



end
