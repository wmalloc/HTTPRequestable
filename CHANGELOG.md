# Changelog

All notable changes to this project will be documented in this file.

## [0.80.1]

### Added
- **HTTPSecurityDelegate**: Task delegate that applies the redirect policy, optional public key pinning and an optional response size limit, and forwards every other callback to a wrapped delegate. Delegates passed to requests are now wrapped in it automatically, so passing one no longer disables redirect protection.
- **HTTPPublicKeyPinning**: Pins by base64 SHA-256 of `SubjectPublicKeyInfo` (the openssl/HPKP format), with backup pins, per-host scoping and optional subdomains. The system validates the chain before pins are checked.
- **Response size limit**: `HTTPSecurityDelegate(maxResponseSize:)` makes `performRequest` stop reading and throw `URLError(.dataLengthExceedsMaximum)` once a response exceeds the limit.

## [0.80.0]

### Fixed
- **HTTPContentType**: Fixed whitespace handling during decoding by using the existing `init(rawValue:)` logic.
- **HTTPRequestConfigurable**: Made `path` property non-optional and updated its default implementation.
- **HTTPRequestConfigurable**: Fixed compilation error in `url` property caused by non-optional `path`.
- **Package.swift**: Excluded `README.md` and `LICENSE` from the `HTTPRequestable` target to prevent them from being processed as resources.

### Changed
- **HTTPContentType**: Removed string-literal equality operator for more predictable behavior.
- **HTTPRequestableMacrosTests**: Added unit tests for macro expansions.
