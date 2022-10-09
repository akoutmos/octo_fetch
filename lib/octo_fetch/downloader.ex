defmodule OctoFetch.Downloader do
  @moduledoc """
  This module defines the callbacks that a GitHub downloader needs
  to implement in order to fetch artifacts from GitHub. `base_url/2` and
  `default_version/0` are automatically implemented for you when you use
  the `OctoFetch` module, but you always have the option to
  override their default implementations.
  """

  @type os() :: :linux | :darwin | :freebsd | :windows
  @type arch() :: :arm64 | :amd64
  @type download_result() :: {:ok, successful_files :: list(), failed_files :: list()} | {:error, String.t()} | :skip

  @doc """
  This callback generates the base URL for the artifact based on the provided GitHub repo
  and the requested version. The default implementation from `OctoFetch` is:

  ```elixir
  def base_url(github_repo, version) do
    "https://github.com/\#{github_repo}/releases/download/v\#{version}/"
  end
  ```
  """
  @callback base_url(github_repo :: String.t(), version :: String.t()) :: String.t()

  @doc """
  This callback returns the default version that sould be downloaded if the
  user does not override the version. It will default to the value of `:latest_version`
  as provided to the `OctoFetch` `__using__/1` macro.
  """
  @callback default_version :: String.t()

  @doc """
  This function must be implemented by your downloader module and is used to
  dynamically generate the name of the download artifact based on the user's
  running environment. For example, for Litestream you would do something like
  so to ensure that users download the proper artifact:

  ```elixir
  def download_name(version, :darwin, arch), do: "litestream-v\#{version}-darwin-\#{arch}.zip"
  def download_name(version, :linux, arch), do: "litestream-v\#{version}-linux-\#{arch}.tar.gz"
  ```
  """
  @callback download_name(version :: String.t(), operation_system :: os(), architecture :: arch()) ::
              String.t()

  @doc """
  This callback is invoked whenever a file is written to the filesystem as
  a result from the download. This callback may be invoked several times
  if the download was an archive file and contained multiple files.
  """
  @callback post_write_hook(file :: String.t()) :: :ok

  @doc """
  This callback is invoked prior to a file being downloaded. This gives you
  the opportunity to skip the download if you so chose by returning `:skip`. Otherwise,
  return `:cont` to continue with the download.
  """
  @callback pre_download_hook(file :: String.t(), output_dir :: String.t()) :: :cont | :skip

  @doc """
  This callback acts as a pass through to the `OctoFetch` module for the
  downloader implementation. See `OctoFetch.download/3` for supported `opts`.
  """
  @callback download(output_dir :: String.t(), opts :: Keyword.t()) :: download_result()
end
