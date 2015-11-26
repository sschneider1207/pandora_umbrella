defmodule PandoraPhoenix.Router do
  use PandoraPhoenix.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PandoraPhoenix do
    pipe_through :browser # Use the default browser stack

    get "/", HomeController, :prompt_login
    post "/", HomeController, :login

    get "/player", PlayerController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", PandoraPhoenix do
  #   pipe_through :api
  # end
end
