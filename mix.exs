defmodule St7789Elixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :st7789_elixir,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
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
      {:circuits_gpio, "~> 0.4"},
      {:circuits_spi, "~> 0.1"}
    ]
  end
end
