# Change log for FileSystemDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- FileSystemDsc
  - Added issue and pull request templates to help contributors.

### Changed

- FileSystemDsc
  - Renamed `master` branch to `main` ([issue #11](https://github.com/dsccommunity/FileSystemDsc/issues/11)).
  - Only run the CI pipeline on branch `master` when there are changes to
    files inside the `source` folder.
  - The regular expression for `minor-version-bump-message` in the file
    `GitVersion.yml` was changed to only raise minor version when the
    commit message contain the word `add`, `adds`, `minor`, `feature`,
    or `features`.
  - Added missing MIT LICENSE file.
  - Converted tests to Pester 5.

### Fixed

- FileSystemDsc
  - The component `gitversion` that is used in the pipeline was wrongly configured
    when the repository moved to the new default branch `main`. It no longer throws
    an error when using newer versions of GitVersion.

## [1.1.1] - 2020-04-19

### Fixed

- FileSystemAccessRule
  - Fixed an issue where the owner of ACL was written back resulting in an
    error "The security identifier is not allowed to be the owner of this
    object" ([issue #3](https://github.com/dsccommunity/FileSystemDsc/issues/3)).

## [1.1.0] - 2020-03-09

### Added

- FileSystemDsc
  - Added resource FileSystemAccessRule
