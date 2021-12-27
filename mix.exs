defmodule St7789Elixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :st7789_elixir,
      version: "0.1.3",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs(),
      source_url: "https://github.com/cocoa-xu/st7789_elixir"
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:cvt_color, "~> 0.1.1"},
      {:circuits_gpio, "~> 0.4"},
      {:circuits_spi, "~> 0.1"},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "ST7789 Elixir driver"
  end

  defp elixirc_paths(_), do: ~w(lib)

  defp docs() do
    [
      groups_for_functions: [
        API: & &1[:functions] == :exported,
        Constants: & &1[:functions] == :constants
      ]
    ]
  end

  defp package() do
    [
      name: "st7789_elixir",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/cocoa-xu/st7789_elixir"}
    ]
  end
end
