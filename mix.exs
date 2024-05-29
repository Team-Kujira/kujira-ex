defmodule Kujira.MixProject do
  use Mix.Project

  def project do
    [
      app: :kujira,
      description: "Elixir interfaces to Kujira dApps, for building indexers, APIs and bots",
      version: "0.1.52",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      maintainers: ["Codehans"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/Team-Kujira/kujira-ex"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.6.12"},
      {:decimal, "~> 2.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:grpc, "~> 0.5.0"},
      {:kujira_proto, "~> 0.9.4"},
      {:jason, "~> 1.2"},
      {:memoize, "~> 1.4"},
      {:websockex, "~> 0.4.3"},
      {:tesla, "~> 1.9"},
      {:hackney, "~> 1.20"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
