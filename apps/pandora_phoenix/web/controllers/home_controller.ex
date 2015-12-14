defmodule PandoraPhoenix.HomeController do
  use PandoraPhoenix.Web, :controller

  def prompt_login(conn, _params) do
    conn = fetch_session(conn)
    case get_session(conn, :username) do
      nil -> render(conn, "login.html")
      _ -> redirect(conn, to: player_path(PandoraPhoenix.Endpoint, :index))
    end
  end

  def login(conn, %{"login" => %{"username" => username, "password" => password}} = _params) do
    PandoraPlayer.login(username, password)
    |> login_reply(conn)
  end

  def delete(conn, _params) do
    conn
    |> clear_session
    |> send_resp(204, "")
  end

  defp login_reply(:ok, %{body_params: %{"login" => %{"username" => username, "password" => password}}} = conn) do
    conn
    |> put_session(:username, username)
    |> put_session(:password, password)
    |> redirect(to: player_path(PandoraPhoenix.Endpoint, :index))
  end
  defp login_reply({:fail, reason}, conn) do
    conn
    |> put_flash(:error, reason)
    |> redirect(to: home_path(PandoraPhoenix.Endpoint, :prompt_login))
  end

end
