defmodule PandoraPhoenix.PlayerController do
  use PandoraPhoenix.Web, :controller

  plug :logged_in?



  @doc """
  Gets everything the view needs to build a player.  This includes:
  1. Station list (gets it if it doesn't exist yet)
  2. Currently selected station (if any)
  3. Current playlist (if any)
  """
  def index(conn, %{"station" => station_token}) do
    conn
    |> fetch_session
    |> put_session(:current_station, station_token)
    |> put_session(:playlist, nil)
    |> render_player(nil)
  end
  def index(conn, params) do
    conn
    |> fetch_session
    |> render_player(params)
  end

  defp render_player(conn, _params) do
    render(conn, "index.html", [stations: nil, selected_station: nil, playlist: nil, now_playing: nil])
  end

  ## station helpers

  defp get_stations(conn) do
    conn
    |> get_session(:stations)
    |> ensure_stations_uptodate(conn)
  end

  defp ensure_stations_uptodate(stations, conn) when is_list(stations), do: {conn, stations}
  defp ensure_stations_uptodate(nil, conn) do
    IO.puts("Downloading station list")
    partner_id = get_session(conn, :partner_id)
    user_auth_token = get_session(conn, :user_auth_token)
    user_id = get_session(conn, :user_id)
    sync_time = get_session(conn, :sync_time)
    time_synced = get_session(conn, :time_synced)
    {stations, _checksum} = PandoraApiClient.get_station_list(partner_id, user_auth_token, user_id, sync_time, time_synced)
    {put_session(conn, :stations, stations), stations}
  end

  ## playlist helpers

  defp get_playlist(conn, selected_station) do
    conn
    |> get_session(:playlist)
    |> ensure_playlist_exists(conn, selected_station)
  end

  defp ensure_playlist_exists(_playlist, conn, nil), do: {conn, nil, nil}
  defp ensure_playlist_exists(nil, conn, selected_station), do: ensure_playlist_exists([], conn, selected_station)
  defp ensure_playlist_exists([], conn, selected_station) do
    partner_id = get_session(conn, :partner_id)
    user_auth_token = get_session(conn, :user_auth_token)
    user_id = get_session(conn, :user_id)
    sync_time = get_session(conn, :sync_time)
    time_synced = get_session(conn, :time_synced)
    [now_playing | playlist] = PandoraApiClient.get_playlist(selected_station, partner_id, user_auth_token, user_id, sync_time, time_synced)
    {put_session(conn, :playlist, playlist), playlist, now_playing}
  end
  defp ensure_playlist_exists([now_playing | playlist], conn, _selected_station), do: {put_session(conn, :playlist, playlist), playlist, now_playing}

  ## plugs

  defp logged_in?(conn, _params) do
    conn
    |> get_session(:username)
    |> redirect_if_nil(conn)
  end

  defp redirect_if_nil(nil, conn), do: conn |> redirect(to: home_path(PandoraPhoenix.Endpoint, :prompt_login)) |> halt
  defp redirect_if_nil(_, conn), do: conn
end
