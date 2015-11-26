defmodule PandoraPhoenix.HomeController do
  use PandoraPhoenix.Web, :controller

  def prompt_login(conn, _params) do
    render(conn, "login.html")
  end

  def login(conn, %{"login" => user} = _params) do
    conn
    |> partner_login
    |> try_login(user)
    |> login_reply
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
    sync_time = get_session(conn, :sync_time)
    result = PandoraApiClient.user_login(username, password, partner_auth_token, partner_id, sync_time)
    {conn, result}
  end

  defp login_reply({conn, {:ok, {user_auth_token, user_id, false}}}), do: login_reply({conn, {:fail, "User isn't authorized to listen."}})
  defp login_reply({%{body_params: %{"login" => %{"username" => username, "password" => password}}} = conn, {:ok, {user_auth_token, user_id, true}}}) do
    conn
    |> put_session(:username, username)
    |> put_session(:password, password)
    |> put_session(:user_auth_token, user_auth_token)
    |> put_session(:user_id, user_auth_token)
    |> json(:ok)
  end
  defp login_reply({conn, {:fail, {_error, _code}}}), do: login_reply({conn, {:fail, "Invalid username or password."}})
  defp login_reply({conn, {:fail, error}}) do
    conn
    |> put_flash(:error, error)
    |> redirect(to: home_path(PandoraPhoenix.Endpoint, :prompt_login))
  end

end
