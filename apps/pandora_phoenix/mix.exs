defmodule PandoraPhoenix.Mixfile do
  use Mix.Project

  def project do
    [app: :pandora_phoenix,
     version: "0.0.1",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.0",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {PandoraPhoenix, []},
     applications: [:phoenix, :phoenix_html, :cowboy, :logger, :pandora_api_client, :pandora_player, :floki]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [{:phoenix, "~> 1.0.3"},
    {:phoenix_html, "~> 2.1"},
    {:phoenix_live_reload, "~> 1.0", only: :dev},
    {:cowboy, "~> 1.0"},
    {:pandora_api_client, in_umbrella: true},
    {:pandora_player, in_umbrella: true},
    {:floki, "~> 0.7.1"}]
  end
end
