//
//  ResponseValidationTests.swift
//
//  Created by Waqar Malik on 11/26/26.
//

import Foundation
@testable import HTTPRequestable
import HTTPTypes
import MockURLProtocol
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

private struct Item: Codable, Equatable {
  let id: Int
}

/// A request for `path` with any result type, using the default transformer and validation for it.
private struct Request<ResultType>: HTTPRequestConfigurable {
  let environment = HTTPEnvironment(authority: "api.example.com")
  let path: String
  var queryItems: [URLQueryItem] = []
  var headerFields: HTTPFields = [:]
  let responseDataTransformer: Transformer<Data, ResultType>
}

private extension Request where ResultType == Void {
  init(path: String) {
    self.init(path: path) { _ in () }
  }
}

private extension Request where ResultType == Data {
  init(path: String) {
    self.init(path: path) { $0 }
  }
}

private struct ItemRequest: HTTPRequestConfigurable {
  typealias ResultType = Item
  let environment = HTTPEnvironment(authority: "api.example.com")
  let path: String
  var queryItems: [URLQueryItem] = []
  var headerFields: HTTPFields = [:]
}

private struct StringRequest: HTTPRequestConfigurable {
  typealias ResultType = String
  let environment = HTTPEnvironment(authority: "api.example.com")
  let path: String
  var queryItems: [URLQueryItem] = []
  var headerFields: HTTPFields = [:]
}

private struct APIError: Error, Decodable, Equatable {
  let message: String
}

/// A request that turns a non-`2xx` JSON body into an ``APIError``.
private struct CustomValidationRequest: HTTPRequestConfigurable {
  typealias ResultType = Item
  let environment = HTTPEnvironment(authority: "api.example.com")
  let path: String
  var queryItems: [URLQueryItem] = []
  var headerFields: HTTPFields = [:]

  func validateResponse(_ response: HTTPClientResponse) throws {
    guard response.response.status.kind == .successful else {
      throw try JSONDecoder().decode(APIError.self, from: response.responseData)
    }
  }
}

/// Expects `body` to throw `HTTPError.unacceptableStatusCode(status)`. `HTTPError` is not `Equatable`,
/// so the case is matched with a pattern.
private func expectUnacceptableStatus(_ status: HTTPResponse.Status, sourceLocation: SourceLocation = #_sourceLocation,
                                      _ body: () async throws -> Void) async {
  let error = await #expect(throws: HTTPError.self, sourceLocation: sourceLocation) {
    try await body()
  }
  guard case .unacceptableStatusCode(let thrown)? = error else {
    Issue.record("Expected HTTPError.unacceptableStatusCode(\(status.code)), got \(String(describing: error))",
                 sourceLocation: sourceLocation)
    return
  }
  #expect(thrown == status, sourceLocation: sourceLocation)
}

struct ResponseValidationTests {
  private let session: URLSession = {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: configuration)
  }()

  /// A path nobody else stubs, so parallel tests cannot take its handler.
  private func uniquePath() -> String {
    "/validation/\(UUID().uuidString)"
  }

  /// Stubs the request's URL with one response.
  private func stub(_ request: some HTTPRequestConfigurable, status: Int, body: String) async throws {
    let url = try request.url
    try await MockURLProtocol.setRequestHandler({ _ in
      let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1",
                                     headerFields: ["Content-Type": "application/json"])!
      return (Data(body.utf8), response)
    }, forIdentifier: url)
  }

  @Test("Error statuses are not decoded as results", arguments: [404, 500, 302, 401])
  func errorStatusesThrow(status: Int) async throws {
    let decodable = ItemRequest(path: uniquePath())
    try await stub(decodable, status: status, body: #"{"id":1}"#)
    await expectUnacceptableStatus(HTTPResponse.Status(code: status)) {
      _ = try await session.object(for: decodable)
    }

    let data = Request<Data>(path: uniquePath())
    try await stub(data, status: status, body: "<html>error</html>")
    await expectUnacceptableStatus(HTTPResponse.Status(code: status)) {
      _ = try await session.object(for: data)
    }

    let string = StringRequest(path: uniquePath())
    try await stub(string, status: status, body: "error")
    await expectUnacceptableStatus(HTTPResponse.Status(code: status)) {
      _ = try await session.object(for: string)
    }
  }

  @Test("Successful statuses are decoded", arguments: [200, 201, 299])
  func successfulStatusesDecode(status: Int) async throws {
    let request = ItemRequest(path: uniquePath())
    try await stub(request, status: status, body: #"{"id":7}"#)
    #expect(try await session.object(for: request) == Item(id: 7))
  }

  @Test("A request can validate the response itself and throw its own error")
  func customValidation() async throws {
    let failing = CustomValidationRequest(path: uniquePath())
    try await stub(failing, status: 422, body: #"{"message":"name is required"}"#)
    await #expect(throws: APIError(message: "name is required")) {
      _ = try await session.object(for: failing)
    }

    let succeeding = CustomValidationRequest(path: uniquePath())
    try await stub(succeeding, status: 200, body: #"{"id":3}"#)
    #expect(try await session.object(for: succeeding) == Item(id: 3))
  }

  @Test("HTTPTransferable.object(for:) validates the status too")
  func transferableValidates() async throws {
    let request = ItemRequest(path: uniquePath())
    try await stub(request, status: 503, body: #"{"id":1}"#)
    let client = ValidationClient(session: session)
    await expectUnacceptableStatus(.serviceUnavailable) {
      _ = try await client.object(for: request)
    }
  }

  @Test("A 204 with an empty body succeeds for Void, Data and String results")
  func emptyBodies() async throws {
    let void = Request<Void>(path: uniquePath())
    try await stub(void, status: 204, body: "")
    try await session.object(for: void)

    let data = Request<Data>(path: uniquePath())
    try await stub(data, status: 204, body: "")
    #expect(try await session.object(for: data).isEmpty)

    let string = StringRequest(path: uniquePath())
    try await stub(string, status: 200, body: "")
    #expect(try await session.object(for: string) == "")
  }

  @Test("An empty body cannot be decoded as JSON")
  func emptyDecodable() async throws {
    let request = ItemRequest(path: uniquePath())
    try await stub(request, status: 204, body: "")
    await #expect(throws: URLError(.zeroByteResource)) {
      _ = try await session.object(for: request)
    }
  }

  @Test("A response without a body is passed to the transformer as empty data")
  func noBody() throws {
    let response = try HTTPClientResponse(request: HTTPRequest(method: .delete, url: #require(URL(string: "https://api.example.com/x"))),
                                          response: HTTPResponse(status: .noContent), responseBody: .empty)
    try response.transformed(using: { (data: Data) in #expect(data.isEmpty) })
    #expect(try response.transformed(using: { $0 }).isEmpty)
  }
}

/// A client that uses the `HTTPTransferable` implementation of `object(for:)`.
private final class ValidationClient: HTTPTransferable, Sendable {
  let session: URLSession
  let requestModifiers: [any HTTPRequestModifier] = []
  let interceptors: [any HTTPInterceptor] = []

  init(session: URLSession) {
    self.session = session
  }
}

struct MultipartMIMETypeTests {
  @Test("Common file name extensions have MIME types", arguments: [
    ("png", "image/png"), ("PNG", "image/png"), ("jpg", "image/jpeg"), ("json", "application/json"), ("txt", "text/plain")
  ])
  func knownExtensions(pathExtension: String, expected: String) {
    #expect(MultipartForm.mimeType(forPathExtension: pathExtension) == expected)
  }

  @Test("Unknown extensions are sent as application/octet-stream")
  func unknownExtension() {
    #expect(MultipartForm.mimeType(forPathExtension: "not-a-real-extension") == "application/octet-stream")
  }
}

struct ContentTypePathExtensionTests {
  @Test("Common file name extensions map to content types, ignoring case", arguments: [
    ("png", HTTPContentType.png), ("PNG", .png), ("jpg", .jpeg), ("JPEG", .jpeg), ("json", .json), ("txt", .textPlain),
    ("pdf", .pdf), ("csv", .csv), ("html", .html), ("svg", .svg), ("zip", .zip), ("mp4", .mp4), ("mov", .quickTime)
  ])
  func known(pathExtension: String, expected: HTTPContentType) {
    #expect(HTTPContentType(pathExtension: pathExtension)?.mimeType == expected.mimeType)
  }

  @Test("Unknown extensions have no content type", arguments: ["not-a-real-extension", "", "."])
  func unknown(pathExtension: String) {
    #expect(HTTPContentType(pathExtension: pathExtension) == nil)
  }

  @Test("The common extensions answer before UTType, so every platform gets the same type")
  func commonTableFirst() {
    for (pathExtension, contentType) in HTTPContentType.commonPathExtensions {
      #expect(pathExtension == pathExtension.lowercased())
      #expect(HTTPContentType(pathExtension: pathExtension) == contentType, "\(pathExtension)")
      #expect(HTTPContentType(pathExtension: pathExtension.uppercased()) == contentType, "\(pathExtension)")
    }
    // UTType says audio/x-m4a; the registered type is audio/mp4.
    #expect(HTTPContentType(pathExtension: "m4a") == .m4a)
  }

  #if canImport(UniformTypeIdentifiers)
  @Test("Other extensions are looked up with UTType")
  func otherExtensionsUseUTType() {
    #expect(HTTPContentType.commonPathExtensions["tiff"] == nil)
    #expect(HTTPContentType(pathExtension: "tiff")?.mimeType == "image/tiff")
  }
  #endif
}
