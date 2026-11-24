# Changelog

All notable changes to this project will be documented in this file.

## [0.80.1]

### Added
- **HTTPSecurityDelegate**: Task delegate that applies the redirect policy, optional public key pinning and an optional response size limit, and forwards every other callback to a wrapped delegate. Delegates passed to requests are now wrapped in it automatically, so passing one no longer disables redirect protection.
- **HTTPPublicKeyPinning**: Pins by base64 SHA-256 of `SubjectPublicKeyInfo` (the openssl/HPKP format), with backup pins, per-host scoping and optional subdomains. The system validates the chain before pins are checked.
- **Response size limit**: `HTTPSecurityDelegate(maxResponseSize:)` makes `performRequest` stop reading and throw `URLError(.dataLengthExceedsMaximum)` once a response exceeds the limit.

### Fixed
- **HTTPTransferable**: `upload(for:from:)`, `upload(for:fromFile:)`, `upload(for:multipartForm:)` and `download(for:)` now apply `HTTPSecurityDelegate`. They previously passed the delegate to `URLSession` unwrapped, so redirects were followed with no redirect policy: credentials went along on cross-origin redirects, https→http redirects were followed, and pinning was skipped.
- **HTTPInterceptor**: Documentation said interceptors run in reverse order. The first interceptor is the outermost: it sees the request first and the response last.
- **HTTPInterceptor**: An interceptor that passed a different delegate to `next` replaced the caller's, which dropped the caller's public key pins and response size limit, and a delegate with no redirect policy turned redirect protection off. The caller's redirect policy, pins and size limit now always apply; the interceptor's delegate receives the remaining callbacks and can only add restrictions (the smaller size limit wins). Platforms without the Objective-C runtime are unchanged.
- **README**: Removed the claim that logging interceptors are provided; none are. Added guidance on keeping credentials out of logs.

### Changed
- **HTTPInterceptor**: When an interceptor moves a request to another origin, sensitive header values the request carried into the chain (for example an `Authorization` header added by a request modifier) are removed; values the interceptor sets itself are kept. Moving an `https` request to another scheme throws `URLError(.appTransportSecurityRequiresSecureConnection)`. Both follow the redirect policy of the caller's delegate, and a delegate substituted by an interceptor cannot relax them.
- **HTTPTransferable**: `bytes(for:)` now applies `requestModifiers`, like every other request method. Interceptors still do not run for streamed requests, and this is now documented.

## [0.80.0]

### Fixed
- **HTTPContentType**: Fixed whitespace handling during decoding by using the existing `init(rawValue:)` logic.
- **HTTPRequestConfigurable**: Made `path` property non-optional and updated its default implementation.
- **HTTPRequestConfigurable**: Fixed compilation error in `url` property caused by non-optional `path`.
- **Package.swift**: Excluded `README.md` and `LICENSE` from the `HTTPRequestable` target to prevent them from being processed as resources.

### Changed
- **HTTPContentType**: Removed string-literal equality operator for more predictable behavior.
- **HTTPRequestableMacrosTests**: Added unit tests for macro expansions.
