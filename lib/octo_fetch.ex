defmodule OctoFetch do
  @moduledoc """
  This library allows you to download release artifacts from GitHub. By using this library
  you get the following functionality for your GitHub downloader client:

  - Automatic SHA validation for downloaded artifacts (security measure to ensure that
    users download valid copies of artifacts)
  - Automatic archive extraction for `.zip` and `.tar.gz` downloads
  - Dynamic artifact downloading based on user's platform
  - Support only specific versions of artifacts from the provided repo

  ## Sample usage

  If you want to make a downloader for the Litestream binary for example, you can define
  a downloader module like so:

  ```elixir
  defmodule LiteStream.Downloader do
    use OctoFetch,
      latest_version: "0.3.9",
      github_repo: "benbjohnson/litestream",
      download_versions: %{
        "0.3.9" => [
          {:darwin, :amd64, "74599a34dc440c19544f533be2ef14cd4378ec1969b9b4fcfd24158946541869"},
          {:linux, :amd64, "806e1cca4a2a105a36f219a4c212a220569d50a8f13f45f38ebe49e6699ab99f"},
          {:linux, :arm64, "61acea9d960633f6df514972688c47fa26979fbdb5b4e81ebc42f4904394c5c5"}
        ],
        "0.3.8" => [
          {:darwin, :amd64, "d359a4edd1cb98f59a1a7c787bbd0ed30c6cc3126b02deb05a0ca501ff94a46a"},
          {:linux, :amd64, "530723d95a51ee180e29b8eba9fee8ddafc80a01cab7965290fb6d6fc31381b3"},
          {:linux, :arm64, "1d6fb542c65b7b8bf91c8859d99f2f48b0b3251cc201341281f8f2c686dd81e2"}
        ]
      }

    # You must implement this function to generate the names of the downloads based on the
    # user's current running environment
    @impl true
    def download_name(version, :darwin, arch), do: "litestream-v\#{version}-darwin-\#{arch}.zip"
    def download_name(version, :linux, arch), do: "litestream-v\#{version}-linux-\#{arch}.tar.gz"
  end
  ```

  You would then be able to download the release artifact by doing the following:

  ```elixir
  Litestream.Downloader.download(".")
  ```

  If you are on an ARM based Mac, the above snippet won't work since Litestream does not currently
  build ARM artifacts. But you can always override what OctoFetch dynamically resolves
  by doing the following:

  ```elixir
  Litestream.Downloader.download(".", override_architecture: :amd64)
  ```

  Be sure to look at the `OctoFetch.download/3` docs for supported options and
  `OctoFetch.Downloader` to see what behaviour callbacks you can override.
  """

  require Logger

  defmacro __using__(opts) do
    # Validated that the required options are provided
    [:latest_version, :github_repo, :download_versions]
    |> Enum.each(fn key ->
      unless Keyword.has_key?(opts, key) do
        raise "#{key} is a required option when calling `use OctoFetch`"
      end
    end)

    latest_version = Keyword.fetch!(opts, :latest_version)

    quote do
      @behaviour OctoFetch.Downloader

      @impl true
      def base_url(github_repo, version) do
        "https://github.com/#{github_repo}/releases/download/v#{version}/"
      end

      @impl true
      def default_version do
        unquote(latest_version)
      end

      @impl true
      def download_name(_, _, _) do
        raise "#{__MODULE__} must implement the download_name/3 callback"
      end

      @impl true
      def post_write_hook(_) do
        :ok
      end

      @impl true
      def pre_download_hook(_, _) do
        :cont
      end

      @impl true
      def download(output_dir, opts \\ []) do
        opts = Keyword.merge(unquote(opts), opts)
        OctoFetch.download(__MODULE__, output_dir, opts)
      end

      @doc false
      def init_opts do
        unquote(opts)
      end

      defoverridable OctoFetch.Downloader
    end
  end

  @doc """
  Download the GitHub release artifact and write it to the specified location.

  The supported `opts` arguments are:

  - `override_version`: By default, the latest version (as specified by the downloader module) will
    be downloaded. But you can also specify any additional versions that are also supported by the
    `:download_versions` map.

  - `override_operating_system`: By default, the operating system is dynamically deteremined based on
     the what the BEAM reports. If you would like to override those results, you can pass
     `:windows`, `:darwin`, or `:linux`.

  - `override_architecture`: By default, the architecture is dynamically deteremined based on
    the what the BEAM reports. If you would like to override those results, you can pass `:amd64`
    or `:arm64`.
  """
  @spec download(downloader_module :: module(), output_dir :: String.t(), opts :: Keyword.t()) ::
          OctoFetch.Downloader.download_result()
  def download(downloader_module, output_dir, opts) do
    version_download_matrix = Keyword.fetch!(opts, :download_versions)
    github_repo = Keyword.fetch!(opts, :github_repo)

    version =
      Keyword.get_lazy(opts, :override_version, fn ->
        downloader_module.default_version()
      end)

    with :ok <- check_output_dir(output_dir),
         {:ok, version_downloads} <- check_requested_version(version, version_download_matrix),
         {:ok, operating_system} <- get_platform_os(opts),
         {:ok, architecture} <- get_platform_architecture(opts),
         {:ok, sha_checksum} <-
           get_sha_for_platform(operating_system, architecture, version_downloads),
         {:ok, github_base_url} <-
           generate_github_base_url(downloader_module, github_repo, version),
         {:ok, artifact_name} <-
           generate_artifact_name(downloader_module, version, operating_system, architecture),
         full_download_url <- Path.join(github_base_url, artifact_name),
         :cont <- downloader_module.pre_download_hook(artifact_name, output_dir),
         {:ok, artifact_contents} <- download_artifact(full_download_url, opts),
         :ok <- verify_artifact_checksum(artifact_contents, sha_checksum, full_download_url),
         {:ok, files_to_write} <-
           maybe_extract_artifact_contents(artifact_contents, artifact_name) do
      {successful_files, failed_files} =
        files_to_write
        |> Enum.reduce({[], []}, fn {file_name, file_contents}, {successful_acc, failed_acc} ->
          file_write_path = Path.join(output_dir, file_name)
          file_write_dir = Path.dirname(file_write_path)

          with {:make_directory, :ok} <- {:make_directory, File.mkdir_p(file_write_dir)},
               {:write_file, :ok} <- {:write_file, File.write(file_write_path, file_contents)} do
            downloader_module.post_write_hook(file_write_path)
            {[file_write_path | successful_acc], failed_acc}
          else
            {:make_directory, error} ->
              Logger.warning("Failed to create directory for #{file_write_path}: #{inspect(error)}")
              {successful_acc, [file_write_path | failed_acc]}

            {:write_file, error} ->
              Logger.warning("Failed to extract #{file_write_path}: #{inspect(error)}")
              {successful_acc, [file_write_path | failed_acc]}
          end
        end)

      {:ok, successful_files, failed_files}
    else
      {:error, reason} ->
        Logger.warning("Failed to download release from GitHub. #{reason}")
        {:error, reason}

      :skip ->
        :skip
    end
  end

  defp check_output_dir(output_dir) do
    if File.exists?(output_dir) do
      :ok
    else
      {:error, "Output directory #{output_dir} does not exist"}
    end
  end

  defp maybe_extract_artifact_contents(artifact_contents, artifact_name) do
    cond do
      String.ends_with?(artifact_name, ".zip") ->
        unzip_download(artifact_contents)

      String.ends_with?(artifact_name, ".tar.gz") ->
        untar_download(artifact_contents)

      true ->
        {:ok, [{artifact_name, artifact_contents}]}
    end
  end

  defp unzip_download(artifact_contents) do
    :zip.extract(artifact_contents, [:memory])
  end

  defp untar_download(artifact_contents) do
    :erl_tar.extract({:binary, artifact_contents}, [:memory, :compressed])
  end

  defp download_artifact(download_url, opts) do
    github_repo = Keyword.fetch!(opts, :github_repo)

    Logger.info("Downloading #{github_repo} from #{download_url}")

    # Ensure that the necessary applications have been started
    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    if proxy = System.get_env("HTTP_PROXY") || System.get_env("http_proxy") do
      Logger.debug("Using HTTP_PROXY: #{proxy}")
      %{host: host, port: port} = URI.parse(proxy)
      :httpc.set_options([{:proxy, {{String.to_charlist(host), port}, []}}])
    end

    if proxy = System.get_env("HTTPS_PROXY") || System.get_env("https_proxy") do
      Logger.debug("Using HTTPS_PROXY: #{proxy}")
      %{host: host, port: port} = URI.parse(proxy)
      :httpc.set_options([{:https_proxy, {{String.to_charlist(host), port}, []}}])
    end

    # https://erlef.github.io/security-wg/secure_coding_and_deployment_hardening/inets
    cacertfile = CAStore.file_path() |> String.to_charlist()

    http_options = [
      ssl: [
        verify: :verify_peer,
        cacertfile: cacertfile,
        depth: 2,
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ],
        versions: protocol_versions()
      ]
    ]

    options = [body_format: :binary]

    case :httpc.request(:get, {download_url, []}, http_options, options) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        {:ok, body}

      error ->
        {:error, "Failed to download #{github_repo} from #{download_url}: #{inspect(error)}"}
    end
  end

  defp verify_artifact_checksum(artifact_contents, known_sha_checksum, download_url) do
    computed_sha =
      :sha256
      |> :crypto.hash(artifact_contents)
      |> Base.encode16()
      |> String.downcase()

    if known_sha_checksum == computed_sha do
      :ok
    else
      {:error, "Invalid SHA256 value computed for #{download_url}"}
    end
  end

  defp protocol_versions do
    if otp_version() < 25, do: [:"tlsv1.2"], else: [:"tlsv1.2", :"tlsv1.3"]
  end

  defp otp_version do
    :erlang.system_info(:otp_release) |> List.to_integer()
  end

  defp get_sha_for_platform(operating_system, architecture, version_downloads) do
    version_downloads
    |> Enum.find_value(fn {os_entry, arch_entry, sha} ->
      if os_entry == operating_system and arch_entry == architecture do
        sha
      end
    end)
    |> case do
      nil ->
        {:error,
         "Your platform is not supported for the provided version (os=#{operating_system}, architecture=#{architecture})"}

      sha ->
        {:ok, sha}
    end
  end

  defp check_requested_version(requested_version, supported_versions) do
    case Map.fetch(supported_versions, requested_version) do
      {:ok, sha_checksums} -> {:ok, sha_checksums}
      _ -> {:error, "#{requested_version} is not a supported version"}
    end
  end

  defp generate_github_base_url(downloader_module, github_repo, version) do
    {:ok, downloader_module.base_url(github_repo, version)}
  end

  defp get_platform_os(opts) do
    opts
    |> Keyword.get_lazy(:override_operating_system, fn ->
      case :os.type() do
        {:win32, _} ->
          :windows

        {:unix, :darwin} ->
          :darwin

        {:unix, :linux} ->
          :linux

        {:unix, :freebsd} ->
          :freebsd

        unknown_os ->
          {:error,
           "Open up an issue at https://github.com/akoutmos/octo_fetch as OS could not be derived for: os=#{inspect(unknown_os)}"}
      end
    end)
    |> case do
      {:error, error} -> {:error, error}
      os -> {:ok, os}
    end
  end

  defp get_platform_architecture(opts) do
    opts
    |> Keyword.get_lazy(:override_architecture, fn ->
      arch_str = :erlang.system_info(:system_architecture)
      [arch | _] = arch_str |> List.to_string() |> String.split("-")

      case {:os.type(), arch, :erlang.system_info(:wordsize) * 8} do
        {{:win32, _}, _arch, 64} ->
          :amd64

        {_os, arch, 64} when arch in ~w(arm aarch64) ->
          :arm64

        {_os, arch, 64} when arch in ~w(amd64 x86_64) ->
          :amd64

        {os, arch, _wordsize} ->
          {:error,
           "Open up an issue at https://github.com/akoutmos/octo_fetch as architecture could not be derived for: os=#{inspect(os)}, arch=#{inspect(arch)}"}
      end
    end)
    |> case do
      {:error, error} -> {:error, error}
      arch -> {:ok, arch}
    end
  end

  defp generate_artifact_name(downloader_module, version, operating_system, architecture) do
    {:ok, downloader_module.download_name(version, operating_system, architecture)}
  end
end
