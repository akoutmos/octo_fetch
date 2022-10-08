defmodule OctoFetch.Test do
  @moduledoc """
  This module contains testing utilities to validate
  downloader modules and their implementations.
  """

  import ExUnit.Assertions, only: [assert: 1]

  @doc """
  Go through all of the supported downloads and validate that
  they work.
  """
  def test_all_supported_downloads(downloader_module) do
    # Get all of the download versions
    download_versions = Keyword.fetch!(downloader_module.init_opts(), :download_versions)

    # Create a place to store the file downloads
    tmp_octo_fetch_dir = Path.join(System.tmp_dir!(), "/octo_fetch_test_downloads")
    File.mkdir_p!(tmp_octo_fetch_dir)

    try do
      download_versions
      |> Enum.each(fn {version, builds} ->
        Enum.each(builds, fn {os, arch, sha} ->
          # A dir for the output of the current build
          current_build_output_dir = Path.join(tmp_octo_fetch_dir, sha)
          File.mkdir_p!(current_build_output_dir)

          assert {:ok, _successful_files, _failed_files} =
                   downloader_module.download(current_build_output_dir,
                     override_version: version,
                     override_operating_system: os,
                     override_architecture: arch
                   )

          File.rm_rf!(current_build_output_dir)
        end)
      end)
    after
      # Delete all of the file downloads
      if File.exists?(tmp_octo_fetch_dir) do
        File.rm_rf!(tmp_octo_fetch_dir)
      end
    end
  end

  @doc """
  Test that the specified version can be downloaded
  """
  def test_version_for_current_platform(downloader_module, version) do
    # Create a place to store the file downloads
    tmp_octo_fetch_dir = Path.join(System.tmp_dir!(), "/octo_fetch_test_downloads")
    File.mkdir_p!(tmp_octo_fetch_dir)

    try do
      # A dir for the output of the current build
      current_build_output_dir = Path.join(tmp_octo_fetch_dir, version)
      File.mkdir_p!(current_build_output_dir)

      assert {:ok, _successful_files, _failed_files} =
               downloader_module.download(current_build_output_dir, override_version: version)

      File.rm_rf!(current_build_output_dir)
    after
      # Delete all of the file downloads
      if File.exists?(tmp_octo_fetch_dir) do
        File.rm_rf!(tmp_octo_fetch_dir)
      end
    end
  end
end
