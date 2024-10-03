defmodule JsonToCsv.MixProject do
  use Mix.Project

  def project do
    [
      app: :json_to_csv,
      version: "0.1.0",
      elixir: "~> 1.14",
      escript: [main_module: MainConverter],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:csv, "~> 2.4"}
    ]
  end
end
