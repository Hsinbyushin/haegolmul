defmodule Haegolmul.MixProject do
  use Mix.Project

  def project do
    [
      app: :haegolmul,
      version: "0.1.0",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Haegolmul.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bandit, "~> 1.0"},
      {:plug, "~> 1.0"},
      {:finch, "~> 0.21"}
    ]
  end
end
