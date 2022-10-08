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
      docs: ["docs", &copy_files/1]
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
  end
end
