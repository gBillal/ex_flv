defmodule ExFLV.MixProject do
  use Mix.Project

  @version "0.1.0"
  @github_url "https://github.com/gBillal/ex_flv"

  def project do
    [
      app: :ex_flv,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "RTMP server and client implementation in Elixir",
      package: package(),

      # docs
      name: "RTMP Server and Client",
      source_url: @github_url,
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Billal Ghilas"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @github_url
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "LICENSE"
      ],
      formatters: ["html"],
      source_ref: "v#{@version}",
      nest_modules_by_prefix: [
        ExFLV.Tag
      ]
    ]
  end
end
