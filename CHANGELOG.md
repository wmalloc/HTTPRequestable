# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Fixed
- **HTTPContentType**: Fixed whitespace handling during decoding by using the existing `init(rawValue:)` logic.
- **HTTPRequestConfigurable**: Made `path` property non-optional and updated its default implementation.
- **HTTPRequestConfigurable**: Fixed compilation error in `url` property caused by non-optional `path`.
- **Package.swift**: Excluded `README.md` and `LICENSE` from the `HTTPRequestable` target to prevent them from being processed as resources.

### Changed
- **HTTPContentType**: Removed string-literal equality operator for more predictable behavior.
- **HTTPRequestableMacrosTests**: Added unit tests for macro expansions.
