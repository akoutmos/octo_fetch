defmodule GithubReleaseFetcherTest do
  use ExUnit.Case
  doctest GithubReleaseFetcher

  test "greets the world" do
    assert GithubReleaseFetcher.hello() == :world
  end
end
