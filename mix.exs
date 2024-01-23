defmodule Kujira.MixProject do
  use Mix.Project

  def project do
    [
      app: :kujira,
      description: "Elixir interfaces to Kujira dApps, for building indexers, APIs and bots",
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
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
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
