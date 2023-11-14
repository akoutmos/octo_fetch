defmodule OctoFetch.MixProject do
  use Mix.Project

  def project do
    [
      app: :octo_fetch,
      version: "0.4.0",
      elixir: "~> 1.13",
      name: "OctoFetch",
      source_url: "https://github.com/akoutmos/octo_fetch",
      homepage_url: "https://hex.pm/packages/octo_fetch",
      description: "Download, verify, and extract GitHub release artifacts effortlessly right from Elixir",
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
      {:castore, "~> 0.1 or ~> 1.0"},
      {:ssl_verify_fun, "~> 1.1"},

      # Development dependencies
      {:ex_doc, "~> 0.30.9", only: :dev},
      {:excoveralls, "~> 0.18.0", only: :test, runtime: false},
      {:credo, "~> 1.7.1", only: :dev},
      {:dialyxir, "~> 1.4.2", only: :dev, runtime: false},
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
      name: "octo_fetch",
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md),
      licenses: ["MIT"],
      maintainers: ["Alex Koutmos"],
      links: %{
        "GitHub" => "https://github.com/akoutmos/octo_fetch",
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
