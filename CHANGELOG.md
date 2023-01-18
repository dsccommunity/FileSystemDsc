# Change log for FileSystemDsc

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- FileSystemDsc
  - Added issue and pull request templates to help contributors.
  - Added wiki generation and publish to GitHub repository wiki.
  - Added recommended VS Code extensions.
    - Added settings for VS Code extension _Pester Test Adapter_.
  - New File resource added to enable cross-platform file operations.

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
  - Minor changes to pipeline files.
  - Update build configuration to use Pester advanced build configuration.
  - Update pipeline to user Sampler GitHub tasks.
  - Update pipeline deploy step to correctly download build artifact.
  - Update so that HQRM test correctly creates a NUnit file that can be
    uploaded to Azure Pipelines.
  - Updated pipeline to use the new faster Pester Code coverage.
  - Using the latest Pester preview version in the pipeline to be able to
    test new Pester functionality.

### Fixed

- FileSystemDsc
  - The component `gitversion` that is used in the pipeline was wrongly configured
    when the repository moved to the new default branch `main`. It no longer throws
    an error when using newer versions of GitVersion.
  - Fix pipeline to use available build workers.
- FileSystemAccessRule
  - Unit test was updated to support latest Pester.
  - Test was updated to handle that `build.ps1` has not been run.

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
