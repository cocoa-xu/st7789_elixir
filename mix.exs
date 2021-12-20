defmodule St7789Elixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :st7789_elixir,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      source_url: "https://github.com/cocoa-xu/st7789_elixir"
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:circuits_gpio, "~> 0.4"},
      {:circuits_spi, "~> 0.1"},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "ST7789 Elixir driver"
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
