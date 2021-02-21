defmodule KBank.MixProject do
  use Mix.Project

  def project do
    [
      app: :kbank,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {KBank, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.4.1"},
      {:poison, "~> 4.0.1"}
    ]
  end
end
