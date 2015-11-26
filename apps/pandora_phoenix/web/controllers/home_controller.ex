defmodule PandoraPhoenix.HomeController do
  use PandoraPhoenix.Web, :controller

  def prompt_login(conn, _params) do
    render conn, "login.html"
  end

  def login(conn, %{"login" => user} = _params) do
    conn
    |> partner_login
    |> try_login(user)
    |> login_reply(conn)
  end

  defp partner_login(conn) do
    {partner_auth_token, partner_id, sync_time, time_synced} = PandoraApiClient.partner_login
    conn
    |> put_session(:partner_auth_token, partner_auth_token)
    |> put_session(:partner_id, partner_id)
    |> put_session(:sync_time, sync_time)
    |> put_session(:time_synced, time_synced)
  end

  defp try_login(conn, %{"username" => username, "password" => password}) do
    partner_auth_token = get_session(conn, :partner_auth_token)
    partner_id = get_session(conn, :partner_id)
    time_synced = get_session(conn, :time_synced)
    PandoraApiClient.user_login(username, password, partner_auth_token, partner_id, time_synced)
  end

  defp login_reply({:ok, {user_auth_token, user_id, can_listen}}, conn) do
    if can_listen do
      conn
      |> put_session(:user_auth_token, user_auth_token)
      |> put_session(:user_id, user_auth_token)
      |> json(:ok)
    else
      login_reply({:fail, "User isn't authorized to listen."}, conn)
    end
  end
  defp login_reply({:fail, {_error, _code}}, conn), do: login_reply({:fail, "Invalid username or password."}, conn)
  defp login_reply({:fail, error}, conn) do
    conn
    |> put_flash(:error, error)
    |> redirect(to: home_path(PandoraPhoenix.Endpoint, :prompt_login))
  end
end
