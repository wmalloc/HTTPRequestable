# Changelog

All notable changes to this project will be documented in this file.

## [0.90.0]

### Added
- **#URL**: Expression macro that turns a string literal into a `URL` checked when you build: `let base = #URL("https://api.example.com/v1")`. The build fails unless the literal is a valid URL with a scheme and a host, written without interpolation, with characters such as spaces already percent-encoded, and without a user name or password. It expands to `URL(string:)!`, which cannot fail because only literals every Foundation version parses the same way are accepted.
- **HTTPRequestConfigurable.pathComponents**: Path segments that are percent-encoded one by one, so a `/` in a value is sent as `%2F` instead of adding segments: `var pathComponents: [String] { ["files", fileName] }`. The default implementation splits `path` on `/`, so existing requests are unchanged.
- **HTTPSecurityDelegate**: Task delegate that applies the redirect policy, optional public key pinning and an optional response size limit, and forwards every other callback to a wrapped delegate. Delegates passed to requests are now wrapped in it automatically, so passing one no longer disables redirect protection.
- **HTTPPublicKeyPinning**: Pins by base64 SHA-256 of `SubjectPublicKeyInfo` (the openssl/HPKP format), with backup pins, per-host scoping and optional subdomains. The system validates the chain before pins are checked.
- **Response size limit**: `HTTPSecurityDelegate(maxResponseSize:)` makes `performRequest` stop reading and throw `URLError(.dataLengthExceedsMaximum)` once a response exceeds the limit.

### Fixed
- **HTTPTransferable**: `upload(for:from:)`, `upload(for:fromFile:)`, `upload(for:multipartForm:)` and `download(for:)` now apply `HTTPSecurityDelegate`. They previously passed the delegate to `URLSession` unwrapped, so redirects were followed with no redirect policy: credentials went along on cross-origin redirects, https→http redirects were followed, and pinning was skipped.
- **HTTPInterceptor**: Documentation said interceptors run in reverse order. The first interceptor is the outermost: it sees the request first and the response last.
- **HTTPInterceptor**: An interceptor that passed a different delegate to `next` replaced the caller's, which dropped the caller's public key pins and response size limit, and a delegate with no redirect policy turned redirect protection off. The caller's redirect policy, pins and size limit now always apply; the interceptor's delegate receives the remaining callbacks and can only add restrictions (the smaller size limit wins). Platforms without the Objective-C runtime are unchanged.
- **README**: Removed the claim that logging interceptors are provided; none are. Added guidance on keeping credentials out of logs.
- **HTTPRequestConfigurable.url**: An environment without a scheme (for example `HTTPEnvironment(string: "api.example.com/v1")`, which parses as a path) crashed in `HTTPRequest(url:)` with "Schemeless URL is not supported". `url` now throws `HTTPError.invalidURL` when the scheme or host is missing. `String` and `URLComponents` conversions to `HTTPRequest` throw `URLError(.badURL)` in the same cases.
- **HTTPRequestConfigurable.url**: A percent-encoded query on the environment was decoded and re-encoded, so `sig=abc%2Bdef` was sent as `sig=abc+def`. It is now kept exactly, and request query items are appended after it. `HTTPEnvironment.appendQueryItems` keeps the existing query the same way.
- **HTTPRequestConfigurable.url**: A percent-encoded `/` in the environment path (`%2F`) was decoded into a separator. The environment path is now kept as it is encoded.

### Changed
- **HTTPInterceptor**: When an interceptor moves a request to another origin, sensitive header values the request carried into the chain (for example an `Authorization` header added by a request modifier) are removed; values the interceptor sets itself are kept. Moving an `https` request to another scheme throws `URLError(.appTransportSecurityRequiresSecureConnection)`. Both follow the redirect policy of the caller's delegate, and a delegate substituted by an interceptor cannot relax them.
- **HTTPTransferable**: `bytes(for:)` now applies `requestModifiers`, like every other request method. Interceptors still do not run for streamed requests, and this is now documented.
- **HTTPRequestConfigurable.url**: Path segments of `.` or `..`, including percent-encoded ones, now throw `HTTPError.invalidURL`. Servers and proxies resolve them, so a value such as `"../admin"` interpolated into `path` could reach a different endpoint.
- **HTTPRequestConfigurable.url** and **HTTPEnvironment.setQueryItems / appendQueryItems**: `+` in query names and values is now sent as `%2B` (and `;` as `%3B`). It was sent as is, and servers decode `+` as a space, which broke values such as emails, phone numbers and signatures.
- **HTTPRequestConfigurable.url**: A user name or password on the environment is now removed from `url`. They were never sent (`HTTPRequest` keeps only the scheme, host and port), so keeping them in `url` only exposed credentials wherever the URL was logged.
- **HTTPEnvironment**: Deprecated `setUser(_:)`, `setPassword(_:)`, `setPercentEncodedUser(_:)` and `setPercentEncodedPassword(_:)`. Credentials set this way were silently not sent; use an `Authorization` header instead.
- **Breaking — HTTPInterceptor.NextHandler** is now `@Sendable`, so interceptors can call `next` from child tasks (for example to race a request against a timeout). Existing `HTTPInterceptor` conformances compile and behave unchanged, including ones that spell out the closure type without `@Sendable`. Code that creates a `NextHandler` closure, for example to call `URLSession.performRequest(_:next:interceptors:delegate:)` or an interceptor directly, must make it `@Sendable`, so it can no longer capture non-`Sendable` values.

## [0.80.0]

### Fixed
- **HTTPContentType**: Fixed whitespace handling during decoding by using the existing `init(rawValue:)` logic.
- **HTTPRequestConfigurable**: Made `path` property non-optional and updated its default implementation.
- **HTTPRequestConfigurable**: Fixed compilation error in `url` property caused by non-optional `path`.
- **Package.swift**: Excluded `README.md` and `LICENSE` from the `HTTPRequestable` target to prevent them from being processed as resources.

### Changed
- **HTTPContentType**: Removed string-literal equality operator for more predictable behavior.
- **HTTPRequestableMacrosTests**: Added unit tests for macro expansions.
