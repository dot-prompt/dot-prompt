defmodule DotPrompt.MixProject do
  use Mix.Project

  def project do
    [
      app: :dot_prompt,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :telemetry],
      mod: {DotPrompt.Application, []}
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:telemetry, "~> 1.2", runtime: false},
      {:telemetry_test, only: :test},
      {:file_system, "~> 0.2"},
      {:credo, "~> 1.7", only: :dev, runtime: false}
    ]
  end
end
