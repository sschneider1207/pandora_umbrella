defmodule PandoraPhoenix.PlayerController do
  use PandoraPhoenix.Web, :controller

  plug :logged_in?

  def index(conn, _params) do
    {conn, stations} = get_stations(conn)
    json(conn, stations)
  end

  defp get_stations(conn) do
    conn
    |> get_session(:stations)
    |> ensure_stations_uptodate(conn)
  end

  defp ensure_stations_uptodate(stations, conn) when is_list(stations), do: {conn, stations}
  defp ensure_stations_uptodate(nil, conn) do
    partner_id = get_session(conn, :partner_id)
    user_auth_token = get_session(conn, :user_auth_token)
    user_id = get_session(conn, :user_id)
    sync_time = get_session(conn, :sync_time)
    time_synced = get_session(conn, :time_synced)
    {stations, _checksum} = PandoraApiClient.get_station_list(partner_id, user_auth_token, user_id, sync_time, time_synced)
    {put_session(conn, :stations, stations), stations}
  end

  defp logged_in?(conn, _params) do
    conn
    |> get_session(:username)
    |> redirect_if_nil(conn)
  end

  defp redirect_if_nil(nil, conn), do: conn |> redirect(to: home_path(PandoraPhoenix.Endpoint, :prompt_login)) |> halt
  defp redirect_if_nil(_, conn), do: conn
end
