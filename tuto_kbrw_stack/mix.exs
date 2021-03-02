defmodule TutoKbrwStack.MixProject do
  use Mix.Project

  def project do
    [
      app: :tuto_kbrw_stack,
      version: "0.1.0",
      elixir: "~> 1.11.3",
      compilers: [:reaxt_webpack] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      application: [:reaxt],
      extra_applications: [:logger, :inets],
      mod: {TutoKbrwStack, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:reaxt, "~> 4.0.1", github: "kbrw/reaxt"},
      {:plug_cowboy, "~> 2.4.1"},
      {:poison, "~> 4.0.1"}
    ]
  end
end
