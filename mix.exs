defmodule GithubReleaseFetcher.MixProject do
  use Mix.Project

  def project do
    [
      app: :github_release_fetcher,
      version: "0.1.0",
      elixir: "~> 1.13",
      name: "GithubReleaseFetcher",
      source_url: "https://github.com/akoutmos/github_release_fetcher",
      homepage_url: "https://hex.pm/packages/github_release_fetcher",
      description: "Download, verify, and extract GitHub releases effortlessly right from Elixir",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.github": :test
      ],
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ],
      package: package(),
      deps: deps(),
      docs: docs(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets, :public_key]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Production dependencies
      {:castore, "~> 0.1.18"},

      # Development dependencies
      {:ex_doc, "~> 0.28.2", only: :dev},
      {:excoveralls, "~> 0.15.0", only: :test, runtime: false},
      {:credo, "~> 1.6.1", only: :dev},
      {:dialyxir, "~> 1.2.0", only: :dev, runtime: false},
      {:git_hooks, "~> 0.7.3", only: [:test, :dev], runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "master",
      logo: "guides/images/logo.svg",
      extras: [
        "README.md"
      ]
    ]
  end

  defp package do
    [
      name: "github_release_fetcher",
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md),
      licenses: ["MIT"],
      maintainers: ["Alex Koutmos"],
      links: %{
        "GitHub" => "https://github.com/akoutmos/github_release_fetcher",
        "Sponsor" => "https://github.com/sponsors/akoutmos"
      }
    ]
  end

  defp aliases do
    [
      docs: [&massage_readme/1, "docs", &copy_files/1]
    ]
  end

  defp copy_files(_) do
    # Set up directory structure
    File.mkdir_p!("./doc/guides/images")

    # Copy over image files
    "./guides/images/"
    |> File.ls!()
    |> Enum.each(fn image_file ->
      File.cp!("./guides/images/#{image_file}", "./doc/guides/images/#{image_file}")
    end)

    # Clean up previous file massaging
    File.rm!("./README.md")
    File.rename!("./README.md.orig", "./README.md")
  end

  defp massage_readme(_) do
    hex_docs_friendly_header_content = """
    <br>
    <img align="center" width="33%" src="guides/images/logo.svg" alt="PromEx Logo" style="margin-left:33%">
    <img align="center" width="70%" src="guides/images/logo_text.png" alt="PromEx Logo" style="margin-left:15%">
    <br>
    <div align="center">Prometheus metrics and Grafana dashboards for all of your favorite Elixir libraries</div>
    <br>
    --------------------
    [![Hex.pm](https://img.shields.io/hexpm/v/prom_ex?style=for-the-badge)](http://hex.pm/packages/prom_ex)
    [![Build Status](https://img.shields.io/github/workflow/status/akoutmos/prom_ex/PromEx%20CI/master?label=Build%20Status&style=for-the-badge)](https://github.com/akoutmos/prom_ex/actions)
    [![Coverage Status](https://img.shields.io/coveralls/github/akoutmos/prom_ex/master?style=for-the-badge)](https://coveralls.io/github/akoutmos/prom_ex?branch=master)
    [![Elixir Slack Channel](https://img.shields.io/badge/slack-%23prom__ex-orange.svg?style=for-the-badge&logo=slack)](https://elixir-lang.slack.com/archives/C01NZ0FBFSR)
    [![Support PromEx](https://img.shields.io/badge/Support%20PromEx-%E2%9D%A4-lightblue?style=for-the-badge)](https://github.com/sponsors/akoutmos)
    """

    File.cp!("./README.md", "./README.md.orig")

    readme_contents = File.read!("./README.md")

    massaged_readme =
      Regex.replace(
        ~r/<!--START-->(.|\n)*<!--END-->/,
        readme_contents,
        hex_docs_friendly_header_content
      )

    File.write!("./README.md", massaged_readme)
  end
end
