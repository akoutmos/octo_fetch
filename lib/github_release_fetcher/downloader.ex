defmodule GithubReleaseFetcher.Downloader do
  @moduledoc """
  This module defines the callbacks that a GitHub downloader needs
  to implement in order to fetch artifacts from GitHub. `base_url/2` and
  `default_version/0` are automatically implemented for you when you use
  the `GithubReleaseFetcher` module, but you always have the option to
  override their default implementations.
  """

  @type os() :: :linux | :macos | :windows
  @type arch() :: :arm64 | :amd64

  @callback base_url(github_repo :: String.t(), version :: String.t()) :: String.t()

  @callback default_version :: String.t()

  @callback download_name(version :: String.t(), operation_system :: os(), architecture :: arch()) ::
              String.t()
end
