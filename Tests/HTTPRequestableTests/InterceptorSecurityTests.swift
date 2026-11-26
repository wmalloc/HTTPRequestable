//
//  InterceptorSecurityTests.swift
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import HTTPRequestable
import HTTPTypes
import Testing

/// A thread-safe list shared between the test, the URL protocol and the interceptors.
private final class Log<Element: Sendable>: @unchecked Sendable {
  // @unchecked: URL protocols and interceptors write from arbitrary threads; every access goes through `lock`.
  private let lock = NSLock()
  private var storage: [Element] = []

  func append(_ element: Element) {
    lock.withLock { storage.append(element) }
  }

  func removeAll() {
    lock.withLock { storage.removeAll() }
  }

  var all: [Element] {
    lock.withLock { storage }
  }
}

/// Records every request it loads. `/redirect` answers with a 302 to `https://other.test/landing`, carrying
/// the original headers the way `URLSession` proposes a redirect; every other path answers 200.
private final class RecordingProtocol: URLProtocol, @unchecked Sendable {
  // @unchecked: URLProtocol is not Sendable; this subclass adds no mutable state.
  static let requests = Log<URLRequest>()

  override class func canInit(with _: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    Self.requests.append(request)
    guard let url = request.url else {
      client?.urlProtocol(self, didFailWithError: URLError(.badURL))
      return
    }
    if url.path == "/redirect" {
      let target = URL(string: "https://other.test/landing")!
      let response = HTTPURLResponse(url: url, statusCode: 302, httpVersion: "HTTP/1.1", headerFields: ["Location": target.absoluteString])!
      var redirected = request
      redirected.url = target
      client?.urlProtocol(self, wasRedirectedTo: redirected, redirectResponse: response)
      return
    }
    let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: Data("ok".utf8))
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {}
}

/// Adds a bearer token for `origin.test` only, like a typical auth modifier.
private struct AuthModifier: HTTPRequestModifier {
  var allowedHosts: Set<String>? {
    ["origin.test"]
  }

  func modify(_ request: inout HTTPRequest, for session: URLSession?) async throws {
    request.headerFields[.authorization] = "Bearer secret"
  }
}

/// Rewrites the request and optionally replaces the delegate before passing it on.
private struct RewritingInterceptor: HTTPInterceptor {
  var rewrite: @Sendable (inout HTTPRequest) -> Void = { _ in }
  var substituteDelegate: (any URLSessionTaskDelegate & Sendable)?

  func intercept(_ request: HTTPRequest, next: @escaping NextHandler, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPClientResponse {
    var request = request
    rewrite(&request)
    return try await next(request, substituteDelegate ?? delegate)
  }
}

/// Logs when the request enters and the response leaves.
private struct OrderInterceptor: HTTPInterceptor {
  let name: String
  let log: Log<String>

  func intercept(_ request: HTTPRequest, next: @escaping NextHandler, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPClientResponse {
    log.append("\(name) in")
    let response = try await next(request, delegate)
    log.append("\(name) out")
    return response
  }
}

/// A delegate with no security settings, standing in for a metrics or progress delegate.
private final class PlainDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
  // @unchecked: NSObject is not Sendable; this subclass has no state.
}

/// Races the rest of the chain against a timeout. Calling `next` from a child task needs a `@Sendable` handler.
private struct TimeoutInterceptor: HTTPInterceptor {
  let timeout: Duration

  func intercept(_ request: HTTPRequest, next: @escaping NextHandler, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPClientResponse {
    try await withThrowingTaskGroup(of: HTTPClientResponse.self) { group in
      group.addTask { try await next(request, nil) }
      group.addTask {
        try await Task.sleep(for: timeout)
        throw URLError(.timedOut)
      }
      defer { group.cancelAll() }
      return try await group.next()!
    }
  }
}

private struct Client: HTTPTransferable {
  let session: URLSession
  var requestModifiers: [any HTTPRequestModifier] = [AuthModifier()]
  var interceptors: [any HTTPInterceptor] = []
}

@Suite(.serialized)
struct InterceptorSecurityTests {
  let session: URLSession = {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [RecordingProtocol.self]
    configuration.timeoutIntervalForRequest = 5
    return URLSession(configuration: configuration)
  }()

  init() {
    RecordingProtocol.requests.removeAll()
  }

  private func authorization(sentTo host: String) -> [String?] {
    RecordingProtocol.requests.all
      .filter { $0.url?.host == host }
      .map { $0.value(forHTTPHeaderField: "Authorization") }
  }

  private func request(_ url: String) throws -> HTTPRequest {
    try HTTPRequest(url: #require(URL(string: url)))
  }

  // MARK: Uploads and downloads keep redirect protection

  #if canImport(ObjectiveC)
  @Test("Data uploads strip credentials on a cross-origin redirect")
  func uploadDataRedirect() async throws {
    _ = try await Client(session: session).upload(for: "https://origin.test/redirect", from: Data("body".utf8))
    #expect(authorization(sentTo: "origin.test") == ["Bearer secret"])
    #expect(authorization(sentTo: "other.test") == [nil])
  }

  @Test("File uploads strip credentials on a cross-origin redirect")
  func uploadFileRedirect() async throws {
    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try Data("body".utf8).write(to: fileURL)
    defer { try? FileManager.default.removeItem(at: fileURL) }

    _ = try await Client(session: session).upload(for: "https://origin.test/redirect", fromFile: fileURL)
    #expect(authorization(sentTo: "origin.test") == ["Bearer secret"])
    #expect(authorization(sentTo: "other.test") == [nil])
  }

  @Test("Downloads strip credentials on a cross-origin redirect")
  func downloadRedirect() async throws {
    let response = try await Client(session: session).download(for: "https://origin.test/redirect")
    if let fileURL = response.responseFileURL {
      try? FileManager.default.removeItem(at: fileURL)
    }
    #expect(authorization(sentTo: "origin.test") == ["Bearer secret"])
    #expect(authorization(sentTo: "other.test") == [nil])
  }
  #endif

  // MARK: Interceptors changing the origin

  @Test("Credentials carried into the chain are removed when an interceptor changes the origin")
  func retargetStripsCarriedCredentials() async throws {
    let interceptor = RewritingInterceptor { $0.authority = "other.test" }
    let client = Client(session: session, interceptors: [interceptor])
    _ = try await client.performRequest(request("https://origin.test/start"), httpBody: nil)
    #expect(authorization(sentTo: "origin.test").isEmpty)
    #expect(authorization(sentTo: "other.test") == [nil])
  }

  @Test("Credentials an interceptor sets for the new origin are kept")
  func retargetKeepsInterceptorCredentials() async throws {
    let interceptor = RewritingInterceptor {
      $0.authority = "other.test"
      $0.headerFields[.authorization] = "Bearer other"
    }
    let client = Client(session: session, interceptors: [interceptor])
    _ = try await client.performRequest(request("https://origin.test/start"), httpBody: nil)
    #expect(authorization(sentTo: "other.test") == ["Bearer other"])
  }

  @Test("Credentials are kept when an interceptor stays on the same origin")
  func sameOriginKeepsCredentials() async throws {
    let interceptor = RewritingInterceptor { $0.path = "/elsewhere" }
    let client = Client(session: session, interceptors: [interceptor])
    _ = try await client.performRequest(request("https://origin.test/start"), httpBody: nil)
    #expect(authorization(sentTo: "origin.test") == ["Bearer secret"])
  }

  @Test("An interceptor cannot downgrade https to http")
  func downgradeFails() async throws {
    let interceptor = RewritingInterceptor { $0.scheme = "http" }
    let client = Client(session: session, interceptors: [interceptor])
    await #expect {
      _ = try await client.performRequest(request("https://origin.test/start"), httpBody: nil)
    } throws: { ($0 as? URLError)?.code == .appTransportSecurityRequiresSecureConnection }
    #expect(RecordingProtocol.requests.all.isEmpty)
  }

  @Test("A delegate substituted by an interceptor does not relax the policy")
  func substitutedDelegateIgnored() async throws {
    let interceptor = RewritingInterceptor(rewrite: { $0.scheme = "http" }, substituteDelegate: HTTPRedirectPolicy(blocksDowngrade: false))
    let client = Client(session: session, interceptors: [interceptor])
    await #expect {
      _ = try await client.performRequest(request("https://origin.test/start"), httpBody: nil)
    } throws: { ($0 as? URLError)?.code == .appTransportSecurityRequiresSecureConnection }
    #expect(RecordingProtocol.requests.all.isEmpty)
  }

  @Test("The caller's redirect policy governs forwarded requests")
  func callerPolicyApplies() throws {
    let original = try request("https://origin.test/start")
    var downgraded = original
    downgraded.scheme = "http"
    #expect(throws: URLError.self) { try HTTPRedirectPolicy.default.forwardedRequest(downgraded, original: original) }
    #expect(throws: Never.self) { try HTTPRedirectPolicy(blocksDowngrade: false).forwardedRequest(downgraded, original: original) }

    #expect(URLSession.redirectPolicy(of: nil) === HTTPRedirectPolicy.default)
    let policy = HTTPRedirectPolicy(blocksDowngrade: false)
    #expect(URLSession.redirectPolicy(of: policy) === policy)
    #if canImport(ObjectiveC) && canImport(Security) && canImport(CryptoKit)
    #expect(URLSession.redirectPolicy(of: HTTPSecurityDelegate(redirectPolicy: policy)) === policy)
    #expect(URLSession.redirectPolicy(of: HTTPSecurityDelegate(redirectPolicy: nil)) === HTTPRedirectPolicy.default)
    #endif
  }

  // MARK: Delegates substituted by interceptors

  #if canImport(ObjectiveC) && canImport(Security) && canImport(CryptoKit)
  @Test("The caller's settings survive an interceptor substituting the delegate")
  func chainedDelegate() {
    let pins = HTTPPublicKeyPinning(publicKeyHashes: ["pin"], hosts: ["origin.test"])
    let caller = HTTPSecurityDelegate(pinning: pins, maxResponseSize: 100)
    #expect(URLSession.chainedTaskDelegate(nil, caller: caller) === caller)
    #expect(URLSession.chainedTaskDelegate(caller, caller: caller) === caller)
    #expect(URLSession.chainedTaskDelegate(nil, caller: nil) === HTTPSecurityDelegate.default)

    let plain = PlainDelegate()
    let chained = URLSession.chainedTaskDelegate(plain, caller: caller) as? HTTPSecurityDelegate
    #expect(chained?.delegate === plain)
    #expect(chained?.pinning == pins)
    #expect(chained?.maxResponseSize == 100)
    #expect(chained?.redirectPolicy === HTTPRedirectPolicy.default)

    let stricter = HTTPSecurityDelegate(maxResponseSize: 10)
    #expect((URLSession.chainedTaskDelegate(stricter, caller: caller) as? HTTPSecurityDelegate)?.maxResponseSize == 10)
    let looser = HTTPSecurityDelegate(redirectPolicy: nil, maxResponseSize: 1000)
    let fromLooser = URLSession.chainedTaskDelegate(looser, caller: caller) as? HTTPSecurityDelegate
    #expect(fromLooser?.maxResponseSize == 100)
    #expect(fromLooser?.redirectPolicy === HTTPRedirectPolicy.default)
    #expect(fromLooser?.pinning == pins)
  }

  @Test("An interceptor passing a delegate with no redirect policy does not turn redirect protection off")
  func substitutedDelegateKeepsRedirectProtection() async throws {
    let interceptor = RewritingInterceptor(substituteDelegate: HTTPSecurityDelegate(redirectPolicy: nil))
    let client = Client(session: session, interceptors: [interceptor])
    _ = try await client.performRequest(request("https://origin.test/redirect"), httpBody: nil)
    #expect(authorization(sentTo: "origin.test") == ["Bearer secret"])
    #expect(authorization(sentTo: "other.test") == [nil])
  }

  @Test("An interceptor substituting the delegate does not remove the caller's response size limit")
  func substitutedDelegateKeepsSizeLimit() async throws {
    let interceptor = RewritingInterceptor(substituteDelegate: PlainDelegate())
    let client = Client(session: session, interceptors: [interceptor])
    await #expect {
      _ = try await client.performRequest(request("https://origin.test/start"), httpBody: nil, delegate: HTTPSecurityDelegate(maxResponseSize: 1))
    } throws: { ($0 as? URLError)?.code == .dataLengthExceedsMaximum }
  }

  @Test("An interceptor can tighten the response size limit")
  func interceptorTightensSizeLimit() async throws {
    let interceptor = RewritingInterceptor(substituteDelegate: HTTPSecurityDelegate(maxResponseSize: 1))
    let client = Client(session: session, interceptors: [interceptor])
    await #expect {
      _ = try await client.performRequest(request("https://origin.test/start"), httpBody: nil, delegate: HTTPSecurityDelegate(maxResponseSize: 1000))
    } throws: { ($0 as? URLError)?.code == .dataLengthExceedsMaximum }
  }
  #endif

  // MARK: Streaming

  #if canImport(ObjectiveC)
  @Test("Streamed requests apply request modifiers")
  func bytesAppliesModifiers() async throws {
    let (bytes, response) = try await Client(session: session).bytes(for: "https://origin.test/start")
    bytes.task.cancel()
    #expect(response.status == .ok)
    #expect(authorization(sentTo: "origin.test") == ["Bearer secret"])
  }
  #endif

  // MARK: Concurrency

  @Test("An interceptor can call next from a child task")
  func nextFromChildTask() async throws {
    let client = Client(session: session, interceptors: [TimeoutInterceptor(timeout: .seconds(5))])
    let response = try await client.performRequest(request("https://origin.test/start"), httpBody: nil)
    #expect(response.response.status == .ok)
    #expect(authorization(sentTo: "origin.test") == ["Bearer secret"])
  }

  // MARK: Order

  @Test("The first interceptor sees the request first and the response last")
  func order() async throws {
    let log = Log<String>()
    let client = Client(session: session, interceptors: [OrderInterceptor(name: "A", log: log), OrderInterceptor(name: "B", log: log)])
    _ = try await client.performRequest(request("https://origin.test/start"), httpBody: nil)
    #expect(log.all == ["A in", "B in", "B out", "A out"])
  }
}
