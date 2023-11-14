# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.0] - 2023-11-14

### Fixed

- Fixed issue when extracting Zip files with directories [#2](https://github.com/akoutmos/octo_fetch/pull/2)

## [0.3.0] - 2023-03-30

### Changed

- Relaxed the `:castore` version requirement

## [0.2.0] - 2022-10-08

### Added

- Support for FreeBSD
- `post_write_hook` callback that is invoked whenever a file is written
- `pre_download_hook` callback that is invoked prior to starting a download

### Changed

- Switched from `:macos` to `:darwin`

## [0.1.0] - 2022-10-08

### Added

- Initial release
