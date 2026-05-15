# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Build
swift build

# Test (uses Apple's Testing framework, not XCTest)
swift test

# Run a single test file
swift test --filter HTTPRequestableTests/<TestFileName>

# Lint
swiftlint

# Format
swiftformat .
```

## Architecture

**HTTPRequestable** is a protocol-based Swift networking library targeting iOS 16+, macOS 12+, tvOS 16+, watchOS 9+, visionOS 1+. It is built on Apple's `swift-http-types` package and uses Swift 6.0 structured concurrency throughout.

### Core Protocol Hierarchy

```
HTTPTransportable          ← raw URLSession operations (data/upload/download/bytes)
    ↑
HTTPTransferable           ← adds requestModifiers[], interceptors[], optional RetryPolicy
    ↑ (adopted by API service classes)
HTTPRequestConfigurable    ← defines a single request (method, path, body, transformer)
```

**HTTPRequestConfigurable** — the primary protocol for defining HTTP requests. Each conforming type declares a `ResultType` associated type and provides `environment`, `method`, `path`, `queryItems`, `headerFields`, `httpBody`, and a `responseDataTransformer`. Default transformers exist for `Void`, `Data`, `String`, and `Decodable`.

**HTTPTransferable** — adopted by API manager/service classes. Holds a `URLSession`, `requestModifiers`, `interceptors`, and an optional `RetryPolicy`. Provides the `object(for:delegate:)`, `upload(for:delegate:)`, `download(for:delegate:)`, and `bytes(for:delegate:)` entry points.

**HTTPTransportable** — lower-level protocol implemented by `URLSession` via extension. Rarely adopted directly.

### Request Lifecycle

```
HTTPRequestConfigurable (define)
  → RequestModifiers applied in order (pre-request, e.g. auth headers, tracing)
  → HTTPRequest / URLRequest built
  → Interceptors applied in reverse order (post-response middleware)
  → URLSession executes
  → responseDataTransformer converts Data → ResultType
  → RetryPolicy governs retries on failure
```

### Key Supporting Types

| Type | Role |
|---|---|
| `HTTPEnvironment` | Typealias for `URLComponents`; base URL builder |
| `HTTPResponseEnvelope` | Wraps request + HTTPResponse + data + optional fileURL |
| `HTTPError` | error cases (invalidURL, cannotCreateURLRequest, contentType, unacceptableStatusCode, etc.) |
| `RetryPolicy` | Exponential backoff: `maxRetries`, `initialDelay`, `multiplier` — lives on `HTTPTransferable` |
| `HTTPRequestModifier` | Pre-request middleware (mutates `HTTPRequest`/`URLRequest`) |
| `HTTPInterceptor` | Post-response middleware with chain pattern (`next` closure) |
| `MultipartForm` | RFC 7578 multipart encoding with streaming support |
| `HTTPContentType` | MIME type with Hashable/Codable |
| `HTTPServerTrustEvaluating` | Certificate pinning and trust validation |

### Interceptor Ordering

Interceptors are applied in **reverse order** — the last interceptor added runs first before the network call and last after. This mirrors URLSession's task delegate chain.

### Modules

- **HTTPRequestable** — main library (`Sources/HTTPRequestable/`)
- **MockURLProtocol** — test utilities (`Sources/MockURLProtocol/`); provides `MockURLProtocol` custom URLProtocol for intercepting requests in tests without hitting the network

### Testing

Tests use Apple's `Testing` framework (`@Test`, `#expect()`), not XCTest. Mock network responses use `MockURLProtocol` from the `MockURLProtocol` target. Test fixtures live in `Tests/HTTPRequestableTests/MockData/`.

### Code Style

- 2-space indentation (SwiftFormat)
- Line length: warn at 150, error at 200
- 52 SwiftLint opt-in rules enabled (see `.swiftlint.yml`)
- All public APIs require Sendable conformance for Swift 6 concurrency
- Performance-critical default implementations are marked `@inlinable`
- Requests are value types; API services are reference types (`final class`)
