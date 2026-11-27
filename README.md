![](https://img.shields.io/github/v/tag/wmalloc/HTTPRequestable?label=Version&sort=semver)
[![CI](https://github.com/wmalloc/HTTPRequestable/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/wmalloc/HTTPRequestable/actions/workflows/ci.yml)
[![Swift](https://img.shields.io/badge/Swift-6.3-orange?style=flat-square)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20iOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS%20%7C%20Linux-yellowgreen?style=flat-square)](#platforms)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://swift.org/package-manager)
![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat)

# HTTPRequestable

A lightweight, type-safe HTTP client for [Swift](https://swift.org), built on `URLSession`,
[Structured Concurrency](https://developer.apple.com/documentation/swift/concurrency) and Apple's
[HTTPTypes](https://github.com/apple/swift-http-types).

You describe each endpoint as a small value type, and the library builds the URL, sends the request,
checks the response and decodes the result. It is secure by default: it strips credentials on
cross-origin redirects, refuses `https` to `http` downgrades, encodes paths and query values so they
cannot change the request, and optionally pins server keys and limits response sizes.

- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Defining requests](#defining-requests)
- [Responses and errors](#responses-and-errors)
- [Request modifiers](#request-modifiers)
- [Interceptors](#interceptors)
- [Retries](#retries)
- [Security](#security)
- [Uploads](#uploads)
- [Content types](#content-types)
- [Macros](#macros)
- [Testing with MockURLProtocol](#testing-with-mockurlprotocol)
- [Platforms](#platforms)
- [Upgrading to 1.0.0](#upgrading-to-100)

## Requirements

- Swift 6.3 or later
- iOS 18, tvOS 18, macOS 15, watchOS 11, Mac Catalyst 18, visionOS 2, or Linux (see [Platforms](#platforms))

## Installation

Add the package to the `dependencies` of your `Package.swift`, and the `HTTPRequestable` product to your
target:

```swift
dependencies: [
  .package(url: "https://github.com/wmalloc/HTTPRequestable.git", from: "1.0.0")
],
targets: [
  .target(name: "MyApp", dependencies: [.product(name: "HTTPRequestable", package: "HTTPRequestable")]),
  .testTarget(name: "MyAppTests", dependencies: ["MyApp", .product(name: "MockURLProtocol", package: "HTTPRequestable")])
]
```

`MockURLProtocol` is only needed by tests; see [Testing](#testing-with-mockurlprotocol).

## Quick start

Define the response, a request that returns it, and a client that sends requests:

```swift
import HTTPRequestable

struct Article: Codable, Sendable {
  let id: Int
  let title: String
}

@Endpoint(path: "/v1/articles")
struct ArticlesRequest: HTTPRequestConfigurable {
  typealias ResultType = [Article]
  let environment: HTTPEnvironment
}

final class APIClient: HTTPTransferable, Sendable {
  let environment = HTTPEnvironment(authority: "api.example.com")
  let session: URLSession
  let requestModifiers: [any HTTPRequestModifier]
  let interceptors: [any HTTPInterceptor] = []

  init(session: URLSession = URLSession(configuration: .default), token: String) {
    self.session = session
    self.requestModifiers = [
      HTTPRequestHeadersModifier.defaultHeaderModifier,
      // Sent only to api.example.com, never to another host.
      HTTPRequestHeadersModifier(fields: [.authorization(bearerToken: token)], allowedHosts: ["api.example.com"]),
    ]
  }

  func articles() async throws -> [Article] {
    try await object(for: ArticlesRequest(environment: environment))
  }
}

let articles = try await APIClient(token: "…").articles()
```

`object(for:)` sends `GET https://api.example.com/v1/articles`, throws unless the status is `2xx`, and
decodes the JSON body into `[Article]`.

## Defining requests

A request conforms to `HTTPRequestConfigurable`. It declares its `ResultType` and `environment`, and
`queryItems` and `headerFields`, which `@Endpoint` adds for you; everything else has a default:

| Member | Default | Purpose |
|---|---|---|
| `environment: HTTPEnvironment` | — | Scheme, host, port and base path, such as `HTTPEnvironment(authority: "api.example.com", path: "/v2")` |
| `method: HTTPMethod` | `.get` | The HTTP method |
| `path: String` | `""` | Path appended to the environment's path |
| `pathComponents: [String]` | `path` split on `/` | Path segments, each percent-encoded on its own |
| `queryItems: [URLQueryItem]` | Added by `@Endpoint` | Query items, appended to any query in the environment |
| `headerFields: HTTPFields` | Added by `@Endpoint` | Header fields for this request |
| `httpBody: Data?` | `nil` | The request body |
| `responseDataTransformer` | For `Void`, `Data`, `String` and `Decodable` | Turns the response body into `ResultType` |
| `validateResponse(_:)` | Accepts `2xx` only | Checks the response before it is decoded |

`@Endpoint` adds `headerFields` and `queryItems`, plus `method` and `path` when you pass them:

```swift
@Endpoint(.get, path: "/v1/articles", headerFields: [.accept: "application/json"], queryItems: ["limit": "20"])
struct LatestArticlesRequest: HTTPRequestConfigurable {
  typealias ResultType = [Article]
  let environment: HTTPEnvironment
}
```

expands to

```swift
struct LatestArticlesRequest: HTTPRequestConfigurable {
  typealias ResultType = [Article]
  let environment: HTTPEnvironment

  var headerFields: HTTPFields = [.accept: "application/json"]
  var method: HTTPMethod { .get }
  var path: String { "/v1/articles" }
  var queryItems: [URLQueryItem] = [URLQueryItem(name: "limit", value: "20")]
}
```

### Paths built from values

When a path segment comes from a value, use `pathComponents`. Each segment is percent-encoded on its own,
so a value such as `"a/b"` is sent as `a%2Fb` and cannot add segments, and a segment of `.` or `..`
throws instead of reaching a different path:

```swift
@Endpoint
struct ArticleRequest: HTTPRequestConfigurable {
  typealias ResultType = Article
  let environment: HTTPEnvironment
  let id: Int

  var pathComponents: [String] { ["v1", "articles", String(id)] }
}
```

### Request bodies

Encode the body when the request is created, so encoding errors are thrown instead of lost:

```swift
struct Draft: Encodable, Sendable {
  let title: String
}

@Endpoint(.post, path: "/v1/articles", headerFields: [.contentType: "application/json"])
struct CreateArticleRequest: HTTPRequestConfigurable {
  typealias ResultType = Article
  let environment: HTTPEnvironment
  let httpBody: Data?

  init(environment: HTTPEnvironment, draft: Draft) throws {
    self.environment = environment
    self.httpBody = try JSONEncoder().encode(draft)
  }
}
```

## Responses and errors

`object(for:)` throws `HTTPError.unacceptableStatusCode` for any status outside `2xx`, so an error page
is never decoded as a result. A `Void` result accepts an empty body, such as a `204 No Content`:

```swift
do {
  let article = try await client.object(for: ArticleRequest(environment: client.environment, id: 42))
  print(article.title)
} catch HTTPError.unacceptableStatusCode(let status) where status == .notFound {
  print("No such article")
}
```

To turn an API's error body into an error of your own, implement `validateResponse(_:)`:

```swift
struct APIError: Error, Decodable {
  let message: String
}

@Endpoint(path: "/v1/me")
struct ProfileRequest: HTTPRequestConfigurable {
  typealias ResultType = Article
  let environment: HTTPEnvironment

  func validateResponse(_ response: HTTPClientResponse) throws {
    guard response.response.status.kind == .successful else {
      if let apiError = try? JSONDecoder().decode(APIError.self, from: response.responseData) {
        throw apiError
      }
      throw HTTPError.unacceptableStatusCode(response.response.status)
    }
  }
}
```

For the raw response, without validation or decoding, use `performRequest(_:)`. It returns an
`HTTPClientResponse` with the `request` that was sent, the `response` (status and headers) and the
`responseData`.

## Request modifiers

Modifiers change every request a client sends, before it goes out. `HTTPRequestHeadersModifier` adds
header fields; `defaultHeaderModifier` adds `Accept-Encoding`, `Accept-Language` and `User-Agent`.
Restrict credentials to the hosts that need them with `allowedHosts`, as in the
[quick start](#quick-start). For anything else, conform to `HTTPRequestModifier`.

## Interceptors

Interceptors wrap each request and its response. They run after the request modifiers, in the order they
are listed: the first interceptor sees the request first and the response last. An interceptor can change
the request, return its own response, or retry by calling `next` again:

```swift
extension HTTPField.Name {
  static let xRequestID = #HTTPFieldName("X-Request-ID")
}

struct RequestIDInterceptor: HTTPInterceptor {
  func intercept(_ request: HTTPRequest, next: @escaping HTTPInterceptor.NextHandler,
                 delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPClientResponse {
    var request = request
    request.headerFields[.xRequestID] = UUID().uuidString
    return try await next(request, delegate)
  }
}
```

- If an interceptor sends the request to a different origin, credential headers the request already
  carried, such as `Authorization`, are removed, and moving an `https` request to `http` fails.
- Interceptors do not run for `bytes(for:)`, which streams the response; request modifiers do.
- No logging interceptor is included. If you write one, keep credentials out of your logs: redact the
  fields in `HTTPRedirectPolicy.defaultSensitiveHeaders` (and any others your API uses), and avoid logging
  request or response bodies.

## Retries

Give a client a `retryPolicy` to retry transient failures:

```swift
final class RetryingClient: HTTPTransferable, Sendable {
  let session = URLSession(configuration: .default)
  let requestModifiers: [any HTTPRequestModifier] = []
  let interceptors: [any HTTPInterceptor] = []
  let retryPolicy: RetryPolicy? = RetryPolicy(maxRetries: 3, initialDelay: 0.5, maxDelay: 10)
}
```

- Network errors such as timeouts and lost connections are retried, and so are `429 Too Many Requests` and
  `503 Service Unavailable` (set `retryableStatuses` to change this). Cancellation and TLS failures are not.
- Only idempotent methods (`GET`, `HEAD`, `PUT`, `DELETE`, `OPTIONS`, `TRACE`) are retried, unless you set
  `retriesNonIdempotentRequests`.
- The delay doubles from `initialDelay` up to `maxDelay`, with jitter so clients do not retry in step.
  A `Retry-After` header can lengthen it; one longer than `maxDelay` ends the retries.
- When the retries are used up, the last response is returned and `object(for:)` throws for its status.

The default is no retries. `RetryPolicy.default` is 3 retries starting at 1 second.

## Security

Every request is protected by default:

- **Redirects**: a redirect to another origin drops `Authorization`, `Cookie`, `Proxy-Authorization` and
  `X-API-Key`, and a redirect from `https` to `http` is not followed. See `HTTPRedirectPolicy`.
- **URLs**: path segments and query values are percent-encoded so they cannot add segments or parameters,
  `.` and `..` segments throw, and a user name or password in the environment is never sent. Use an
  `Authorization` header instead.
- **Header values**: `KeyedItem`, `Quality` and `HTTPContentType` reject values that would produce invalid
  or injected headers.

On Apple platforms, pass an `HTTPSecurityDelegate` to pin server keys or limit response sizes:

```swift
let pins = HTTPPublicKeyPinning(publicKeyHashes: ["<primary pin>", "<backup pin>"], hosts: ["api.example.com"])
let delegate = HTTPSecurityDelegate(pinning: pins, maxResponseSize: 5_000_000)
let articles = try await client.object(for: ArticlesRequest(environment: client.environment), delegate: delegate)
```

A pin is the base64 SHA-256 of a certificate's public key. Always include a backup pin, such as the key of
your next certificate, so a certificate change does not lock users out:

```sh
openssl s_client -connect api.example.com:443 -servername api.example.com </dev/null \
  | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64
```

Pinning applies only when the session's own delegate does not handle server trust challenges.

## Uploads

Build a multipart form and upload it:

```swift
@Endpoint(.post, path: "/v1/uploads")
struct UploadRequest: HTTPRequestConfigurable {
  typealias ResultType = Data
  let environment: HTTPEnvironment
}

let form = MultipartForm()
form.append(data: Data("A short note".utf8), withName: "note")
form.append(data: imageData, withName: "photo", fileName: "photo.png", mimeType: "image/png")
let response = try await client.upload(for: UploadRequest(environment: client.environment), multipartForm: form)
try response.validateStatus()
```

`upload(for:from:)` and `upload(for:fromFile:)` send a body from memory or from a file, and
`download(for:)` saves the response to a file.

## Content types

`HTTPContentType` parses and checks media types:

```swift
let contentType = HTTPContentType(rawValue: "application/json; charset=utf-8")  // nil if invalid
contentType?.mimeType                                // "application/json"
contentType?.parameters["charset"]                   // "utf-8"
HTTPContentType("text/*").matches(.html)             // true
HTTPContentType(pathExtension: "png")                // image/png
```

Common types are available as constants, such as `.json`, `.html`, `.png` and `.pdf`.
`HTTPClientResponse.validate()` checks the status and that the `Content-Type` matches the request's
`Accept` header.

## Macros

### @Endpoint
Adds a request's members; see [Defining requests](#defining-requests).

### #URL
Creates a `URL` from a string literal that is checked when you build, so it needs no `!` or `try`:

```swift
let base = #URL("https://api.example.com/v1")
```

The build fails if the literal isn't a valid URL with a scheme and a host, contains interpolation or
unencoded characters such as spaces, or includes a user name or password.

### #HTTPFieldName
Creates an `HTTPField.Name` from a string literal that is checked when you build, so it needs no `!`:

```swift
extension HTTPField.Name {
  static let requestID = #HTTPFieldName("X-Request-ID")
}
```

The build fails if the literal is empty, contains interpolation, or has a character not allowed in a
field name, such as a space, a colon or a line break.

## Testing with MockURLProtocol

`MockURLProtocol` answers requests from handlers you register, so tests never reach the network. Give
the client a session that uses it, and register a handler for each request:

```swift
import HTTPRequestable
import MockURLProtocol
import Testing

@Test func loadsArticles() async throws {
  let configuration = URLSessionConfiguration.ephemeral
  configuration.protocolClasses = [MockURLProtocol.self]
  let client = APIClient(session: URLSession(configuration: configuration), token: "test")

  try await MockURLProtocol.setRequestHandler({ request in
    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil,
                                   headerFields: ["Content-Type": "application/json"])!
    return (Data(#"[{"id": 1, "title": "Hello"}]"#.utf8), response)
  }, forRequest: ArticlesRequest(environment: client.environment))

  let articles = try await client.articles()
  #expect(articles.map(\.title) == ["Hello"])
}
```

- A handler is matched by the request's URL, and answers one request.
- When several tests use the same URL, give each request its own identifier with
  `byAddingMockIdentifierHeader()`, which sets an `X-Mock-Identifier` header the handler is keyed by.
- `setRequestHandler(_:forIdentifier:)` registers a handler for a URL or identifier directly.

## Platforms

Everything works on Apple platforms. On Linux the package builds and its tests run, but these need
Apple-only Foundation APIs and are not available there:

- `bytes(for:)` (streamed responses)
- `HTTPSecurityDelegate`, `HTTPPublicKeyPinning` and the response size limit
- The `URLRequest` setters `setAttribution(_:)`, `setAllowsConstrainedNetworkAccess(_:)`,
  `setAllowsExpensiveNetworkAccess(_:)` and `setAssumesHTTP3Capable(_:)`

Redirect protection still applies on Linux, but a delegate you pass replaces it instead of being wrapped.

## Upgrading to 1.0.0

1.0.0 has two breaking changes:

- **`object(for:)` checks the status.** A response outside `2xx` now throws
  `HTTPError.unacceptableStatusCode` instead of being decoded. If an API returns useful bodies with other
  statuses, implement `validateResponse(_:)` on the request.
- **The `URLRequest` builder keeps only typed setters.** Use `setMethod(_:)` instead of
  `setHttpMethod(_: String?)`, `setHttpHeader(_:forField:)` or `setHeader(_:)` instead of the `forName:`
  versions, `setHttpHeaderFields(_:)` instead of `setHttpHeaders(_: [String: String])`, and the
  `HTTPContentType` versions of `setHttpBody(_:contentType:)` and `setContentType(_:)`.
  `setMaindocumentURL(_:)` is now `setMainDocumentURL(_:)`, and `setAllowsConstraintNetworkAccess(_:)` is
  now `setAllowsConstrainedNetworkAccess(_:)`.

See [CHANGELOG.md](CHANGELOG.md) for everything else in this release.

## Running the tests

```sh
swift test                                       # the package, without network access
(cd Sample/Modules/HackerNewsKit && swift test)  # the sample client
HTTPREQUESTABLE_LIVE_TESTS=1 swift test          # also call the live Hacker News API
```

Tests that call the live API are tagged `live` and skipped unless `HTTPREQUESTABLE_LIVE_TESTS=1` is set,
so the suite passes offline. CI runs these on macOS and Linux; see `.github/workflows/ci.yml`.

## License

**HTTPRequestable** is released under the MIT license. See LICENSE for details.

## Support

If you would like to support this project, please consider donating.\
Bitcoin: [bc1qzxs3wk29vfxlr9e4frq9cdmgkvrp62m5xhm93l](./Images/bitcoin_qr_code.jpeg)\
Ethereum: [0xa824353280d2A0F32b2d258904509EFAEaE6603d](./Images/ethereum_qr_code.jpeg)
