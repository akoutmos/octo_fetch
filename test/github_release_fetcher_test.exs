defmodule GithubReleaseFetcherTest do
  use ExUnit.Case
  doctest GithubReleaseFetcher

  defmodule Litestream.Fetcher do
    use GithubReleaseFetcher,
      latest_version: "0.3.9",
      github_repo: "benbjohnson/litestream",
      download_versions: %{
        "0.3.9" => [
          {:linux, :amd64, "806e1cca4a2a105a36f219a4c212a220569d50a8f13f45f38ebe49e6699ab99f"}
        ],
        "0.3.8" => [
          {:linux, :amd64, "530723d95a51ee180e29b8eba9fee8ddafc80a01cab7965290fb6d6fc31381b3"}
        ]
      }

    @impl true
    def download_name(version, :macos, arch), do: "litestream-v#{version}-darwin-#{arch}.zip"
    def download_name(version, :linux, arch), do: "litestream-v#{version}-linux-#{arch}.tar.gz"
  end

  test "greets the world" do
    GithubReleaseFetcher.Test.test_all_supported_downloads(Litestream.Fetcher)
  end
end
