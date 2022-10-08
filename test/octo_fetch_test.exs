defmodule OctoFetchTest do
  use ExUnit.Case

  import ExUnit.CaptureLog

  defmodule Litestream.Fetcher do
    use OctoFetch,
      latest_version: "0.3.9",
      github_repo: "benbjohnson/litestream",
      download_versions: %{
        "0.3.9" => [
          {:linux, :amd64, "806e1cca4a2a105a36f219a4c212a220569d50a8f13f45f38ebe49e6699ab99f"},
          {:darwin, :amd64, "74599a34dc440c19544f533be2ef14cd4378ec1969b9b4fcfd24158946541869"},
          {:darwin, :arm64, "74599a34dc440c19544f533be2ef14cd4378ec1969b9b4fcfd24158946541869"}
        ],
        "0.3.8" => [
          {:linux, :amd64, "530723d95a51ee180e29b8eba9fee8ddafc80a01cab7965290fb6d6fc31381b3"}
        ]
      }

    @impl true
    def download_name(version, :darwin, _arch), do: "litestream-v#{version}-darwin-amd64.zip"
    def download_name(version, :linux, arch), do: "litestream-v#{version}-linux-#{arch}.tar.gz"
  end

  test "Should download all of the specified versions" do
    OctoFetch.Test.test_all_supported_downloads(Litestream.Fetcher)
  end

  test "Should download the specified version on the current platform" do
    OctoFetch.Test.test_version_for_current_platform(Litestream.Fetcher, "0.3.9")
  end

  test "Should return an error if an invalid version is provided" do
    capture_log(fn ->
      assert {:error, "invalid is not a supported version"} =
               Litestream.Fetcher.download(".", override_version: "invalid")
    end) =~ "invalid is not a supported version"
  end

  test "Should return an error if an invalid output directory is provided" do
    capture_log(fn ->
      assert {:error, "Output directory ./this/dir/does/not/exist does not exist"} =
               Litestream.Fetcher.download("./this/dir/does/not/exist")
    end) =~ "Output directory ./this/dir/does/not/exist does not exist"
  end

  test "Should return an error if an invalid architecture is provided" do
    capture_log(fn ->
      assert {:error, "Your platform is not supported for the provided version" <> _} =
               Litestream.Fetcher.download(".", override_architecture: :bad_arch)
    end) =~ "Your platform is not supported for the provided version"
  end

  test "Should return an error if an invalid OS is provided" do
    capture_log(fn ->
      assert {:error, "Your platform is not supported for the provided version" <> _} =
               Litestream.Fetcher.download(".", override_operating_system: :bad_os)
    end) =~ "Your platform is not supported for the provided version"
  end

  @tag :tmp_dir
  test "Should return an :ok tuple with the archive files", %{tmp_dir: tmp_dir} do
    expected_output = Path.join(tmp_dir, "litestream")
    assert {:ok, [^expected_output], []} = Litestream.Fetcher.download(tmp_dir)
  end
end
