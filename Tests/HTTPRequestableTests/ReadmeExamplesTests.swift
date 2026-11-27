//
//  ReadmeExamplesTests.swift
//
//  Created by Waqar Malik on 11/27/26.
//

import Foundation
import HTTPRequestable
import HTTPTypes
import MockURLProtocol
import Synchronization
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// The examples from README.md, compiled and run so the README cannot fall out of date. Keep each type
// here identical to its README version; they are inside `ReadmeExamples` only so their names cannot
// clash with other tests.

extension HTTPField.Name {
  static let xRequestID = #HTTPFieldName("X-Request-ID")
}

enum ReadmeExamples {
  // MARK: Quick start

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
        HTTPRequestHeadersModifier(fields: [.authorization(bearerToken: token)], allowedHosts: ["api.example.com"])
      ]
    }

    func articles() async throws -> [Article] {
      try await object(for: ArticlesRequest(environment: environment))
    }
  }

  // MARK: Defining requests

  @Endpoint(.get, path: "/v1/articles", headerFields: [.accept: "application/json"], queryItems: ["limit": "20"])
  struct LatestArticlesRequest: HTTPRequestConfigurable {
    typealias ResultType = [Article]
    let environment: HTTPEnvironment
  }

  @Endpoint
  struct ArticleRequest: HTTPRequestConfigurable {
    typealias ResultType = Article
    let environment: HTTPEnvironment
    let id: Int

    var pathComponents: [String] {
      ["v1", "articles", String(id)]
    }
  }

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

  // MARK: Responses and errors

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

  // MARK: Interceptors

  struct RequestIDInterceptor: HTTPInterceptor {
    func intercept(_ request: HTTPRequest, next: @escaping HTTPInterceptor.NextHandler,
                   delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPClientResponse {
      var request = request
      request.headerFields[.xRequestID] = UUID().uuidString
      return try await next(request, delegate)
    }
  }

  // MARK: Retries

  final class RetryingClient: HTTPTransferable, Sendable {
    let session = URLSession(configuration: .default)
    let requestModifiers: [any HTTPRequestModifier] = []
    let interceptors: [any HTTPInterceptor] = []
    let retryPolicy: RetryPolicy? = RetryPolicy(maxRetries: 3, initialDelay: 0.5, maxDelay: 10)
  }

  // MARK: Uploads

  @Endpoint(.post, path: "/v1/uploads")
  struct UploadRequest: HTTPRequestConfigurable {
    typealias ResultType = Data
    let environment: HTTPEnvironment
  }
}

/// A client like `APIClient` that also runs interceptors, for the interceptor example.
private final class InterceptingClient: HTTPTransferable, Sendable {
  let environment = HTTPEnvironment(authority: "api.example.com")
  let session: URLSession
  let requestModifiers: [any HTTPRequestModifier] = []
  let interceptors: [any HTTPInterceptor] = [ReadmeExamples.RequestIDInterceptor()]

  init(session: URLSession) {
    self.session = session
  }
}

/// The requests a stub received.
private final class SentRequests: Sendable {
  private let requests = Mutex<[URLRequest]>([])

  func append(_ request: URLRequest) {
    requests.withLock { $0.append(request) }
  }

  var first: URLRequest? {
    requests.withLock { $0.first }
  }
}

/// Serialized because several examples use the same URLs, and `MockURLProtocol` keys handlers by URL.
@Suite("README examples", .serialized)
struct ReadmeExamplesTests {
  typealias Article = ReadmeExamples.Article
  typealias ArticlesRequest = ReadmeExamples.ArticlesRequest
  typealias APIClient = ReadmeExamples.APIClient

  private func mockSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: configuration)
  }

  private func stub(_ request: some HTTPRequestConfigurable, status: Int = 200, body: String,
                    record: SentRequests? = nil) async throws {
    let url = try request.url
    try await MockURLProtocol.setRequestHandler({ sent in
      record?.append(sent)
      let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil,
                                     headerFields: ["Content-Type": "application/json"])!
      return (Data(body.utf8), response)
    }, forIdentifier: url)
  }

  /// The "Testing with MockURLProtocol" example, as written in the README.
  @Test("The testing example loads articles")
  func loadsArticles() async throws {
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

  @Test("The quick start client sends the documented request with its modifiers")
  func quickStart() async throws {
    let client = APIClient(session: mockSession(), token: "secret")
    let sent = SentRequests()
    try await stub(ArticlesRequest(environment: client.environment), body: #"[{"id": 1, "title": "Hello"}]"#, record: sent)

    let articles = try await client.articles()
    #expect(articles.map(\.id) == [1])
    let request = try #require(sent.first)
    #expect(request.url?.absoluteString == "https://api.example.com/v1/articles")
    #expect(request.httpMethod == "GET")
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
    #expect(request.value(forHTTPHeaderField: "User-Agent") != nil)
  }

  @Test("The defining-requests examples build the documented requests")
  func definingRequests() throws {
    let environment = HTTPEnvironment(authority: "api.example.com")
    let latest = ReadmeExamples.LatestArticlesRequest(environment: environment)
    #expect(try latest.url.absoluteString == "https://api.example.com/v1/articles?limit=20")
    #expect(latest.method == .get)
    #expect(latest.headerFields[.accept] == "application/json")

    #expect(try ReadmeExamples.ArticleRequest(environment: environment, id: 42).url.absoluteString
      == "https://api.example.com/v1/articles/42")

    let create = try ReadmeExamples.CreateArticleRequest(environment: environment, draft: ReadmeExamples.Draft(title: "Hi"))
    #expect(create.method == .post)
    #expect(create.httpBody == Data(#"{"title":"Hi"}"#.utf8))
    #expect(create.headerFields[.contentType] == "application/json")
  }

  @Test("The error example catches a 404")
  func notFound() async throws {
    let client = APIClient(session: mockSession(), token: "test")
    let request = ReadmeExamples.ArticleRequest(environment: client.environment, id: 42)
    try await stub(request, status: 404, body: #"{"message": "missing"}"#)

    var caught: HTTPResponse.Status?
    do {
      let article = try await client.object(for: request)
      Issue.record("Expected a 404, got \(article.title)")
    } catch HTTPError.unacceptableStatusCode(let status) where status == .notFound {
      caught = status
    }
    #expect(caught == .notFound)
  }

  @Test("The validateResponse example throws the API's own error")
  func customValidation() async throws {
    let client = APIClient(session: mockSession(), token: "test")
    let request = ReadmeExamples.ProfileRequest(environment: client.environment)
    try await stub(request, status: 401, body: #"{"message": "Sign in again"}"#)
    let error = await #expect(throws: ReadmeExamples.APIError.self) {
      _ = try await client.object(for: request)
    }
    #expect(error?.message == "Sign in again")
  }

  @Test("The interceptor example adds a request ID")
  func interceptor() async throws {
    let client = InterceptingClient(session: mockSession())
    let request = ReadmeExamples.ArticleRequest(environment: client.environment, id: 7)
    let sent = SentRequests()
    try await stub(request, body: #"{"id": 7, "title": "Seven"}"#, record: sent)
    _ = try await client.object(for: request)
    let id = sent.first?.value(forHTTPHeaderField: "X-Request-ID")
    #expect(id.flatMap(UUID.init(uuidString:)) != nil)
  }

  @Test("The retry example configures the documented policy")
  func retries() throws {
    let policy = try #require(ReadmeExamples.RetryingClient().retryPolicy)
    #expect(policy.maxRetries == 3)
    #expect(policy.initialDelay == 0.5)
    #expect(policy.maxDelay == 10)
    #expect(RetryPolicy.default.maxRetries == 3)
    #expect(RetryPolicy.default.initialDelay == 1)
  }

  #if canImport(ObjectiveC) && canImport(Security) && canImport(CryptoKit)
  @Test("The security example sends a request with pinning and a size limit")
  func security() async throws {
    let client = APIClient(session: mockSession(), token: "test")
    try await stub(ArticlesRequest(environment: client.environment), body: #"[{"id": 2, "title": "Pinned"}]"#)

    let pins = HTTPPublicKeyPinning(publicKeyHashes: ["<primary pin>", "<backup pin>"], hosts: ["api.example.com"])
    let delegate = HTTPSecurityDelegate(pinning: pins, maxResponseSize: 5000000)
    let articles = try await client.object(for: ArticlesRequest(environment: client.environment), delegate: delegate)
    #expect(articles.map(\.title) == ["Pinned"])
  }
  #endif

  @Test("The upload example sends a multipart form")
  func upload() async throws {
    let client = APIClient(session: mockSession(), token: "test")
    let sent = SentRequests()
    try await stub(ReadmeExamples.UploadRequest(environment: client.environment), body: "{}", record: sent)
    let imageData = Data([0x89, 0x50, 0x4E, 0x47])

    let form = MultipartForm()
    form.append(data: Data("A short note".utf8), withName: "note")
    form.append(data: imageData, withName: "photo", fileName: "photo.png", mimeType: "image/png")
    let response = try await client.upload(for: ReadmeExamples.UploadRequest(environment: client.environment), multipartForm: form)
    try response.validateStatus()

    let request = try #require(sent.first)
    #expect(request.httpMethod == "POST")
    #expect(request.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data; boundary=") == true)
  }

  @Test("The content type example returns the documented values")
  func contentTypes() {
    let contentType = HTTPContentType(rawValue: "application/json; charset=utf-8")
    #expect(contentType?.mimeType == "application/json")
    #expect(contentType?.parameters["charset"] == "utf-8")
    #expect(HTTPContentType("text/*").matches(.html))
    #expect(HTTPContentType(pathExtension: "png") == .png)
    #expect(HTTPContentType(rawValue: "not a type") == nil)
  }

  @Test("The macro examples produce the documented values")
  func macros() {
    #expect(#URL("https://api.example.com/v1").absoluteString == "https://api.example.com/v1")
    #expect(HTTPField.Name.xRequestID.rawName == "X-Request-ID")
  }
}
