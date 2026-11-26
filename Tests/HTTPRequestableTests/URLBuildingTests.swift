//
//  URLBuildingTests.swift
//

import Foundation
@testable import HTTPRequestable
import HTTPTypes
import Testing

private struct Request: HTTPRequestConfigurable {
  typealias ResultType = Data
  var environment: HTTPEnvironment = .init(authority: "api.example.com", path: "/v1")
  var path: String = ""
  var queryItems: [URLQueryItem] = []
  var headerFields: HTTPFields = [:]
}

private struct SegmentRequest: HTTPRequestConfigurable {
  typealias ResultType = Data
  var environment: HTTPEnvironment = .init(authority: "api.example.com", path: "/v1")
  var segments: [String]
  var pathComponents: [String] {
    segments
  }

  var queryItems: [URLQueryItem] = []
  var headerFields: HTTPFields = [:]
}

struct URLBuildingTests {
  private func url(_ request: some HTTPRequestConfigurable) throws -> String {
    try request.url.absoluteString
  }

  private func expectInvalid(_ request: some HTTPRequestConfigurable, sourceLocation: SourceLocation = #_sourceLocation) {
    #expect(sourceLocation: sourceLocation) {
      _ = try request.httpRequest
    } throws: { error in
      guard case HTTPError.invalidURL = error else { return false }
      return true
    }
  }

  // MARK: Scheme and host

  @Test("A missing scheme throws instead of trapping in HTTPRequest(url:)")
  func missingScheme() throws {
    // Parses as a path: no scheme and no host.
    let environment = try #require(HTTPEnvironment(string: "api.example.com/v1"))
    expectInvalid(Request(environment: environment, path: "items"))
  }

  @Test("A missing host throws")
  func missingHost() {
    expectInvalid(Request(environment: HTTPEnvironment().setScheme("https"), path: "items"))
    expectInvalid(Request(environment: HTTPEnvironment(authority: ""), path: "items"))
  }

  @Test("Strings and components without a scheme or host throw instead of trapping", arguments: ["items", "/v1/items", "https:/items", "mailto:someone"])
  func convertibleWithoutSchemeOrHost(string: String) {
    #expect(throws: URLError.self) { _ = try string.httpRequest }
    #expect(throws: URLError.self) { _ = try URLComponents(string: string)?.httpRequest }
  }

  @Test("Complete strings still convert")
  func convertibleComplete() throws {
    let request = try "https://api.example.com/v1/items?x=1".httpRequest
    #expect(request.authority == "api.example.com")
    #expect(request.path == "/v1/items?x=1")
  }

  // MARK: User info

  @Test("User info on the environment is removed from the URL, matching what is sent")
  func userInfoRemoved() throws {
    let parsed = try #require(HTTPEnvironment(string: "https://alice:s3cret@api.example.com/v1"))
    var assigned = HTTPEnvironment(authority: "api.example.com", path: "/v1")
    assigned.user = "alice"
    assigned.percentEncodedPassword = "s%33cret"

    for environment in [parsed, assigned] {
      let request = Request(environment: environment, path: "me")
      let url = try request.url
      #expect(url.absoluteString == "https://api.example.com/v1/me")
      #expect(url.user == nil && url.password == nil)
      #expect(try request.httpRequest.authority == "api.example.com")
      #expect(try request.urlRequest.url?.absoluteString.contains("s3cret") == false)
    }
  }

  // MARK: Path

  @Test("String paths are built as before", arguments: [
    ("items", "https://api.example.com/v1/items"),
    ("/items//detail/", "https://api.example.com/v1/items/detail"),
    ("a b/c?d#e", "https://api.example.com/v1/a%20b/c%3Fd%23e"),
    ("", "https://api.example.com/v1"),
    ("//evil.example.org/x", "https://api.example.com/v1/evil.example.org/x")
  ])
  func stringPaths(path: String, expected: String) throws {
    #expect(try url(Request(path: path)) == expected)
  }

  @Test("Dot segments throw", arguments: ["users/../admin", "./items", "..", "a/./b"])
  func dotSegmentsInPath(path: String) {
    expectInvalid(Request(path: path))
  }

  @Test("A literal %2e%2e in the path is encoded, so it is not a dot segment")
  func encodedDotsInPath() throws {
    #expect(try url(Request(path: "users/%2e%2E/admin")) == "https://api.example.com/v1/users/%252e%252E/admin")
  }

  @Test("Dot segments in the environment path throw, also when percent-encoded")
  func dotSegmentsInEnvironment() {
    expectInvalid(Request(environment: HTTPEnvironment(authority: "api.example.com").setPercentEncodedPath("/v1/%2E%2e"), path: "items"))
    expectInvalid(Request(environment: HTTPEnvironment(authority: "api.example.com", path: "/v1/../admin")))
  }

  @Test("Path components are encoded one by one, so a slash cannot add a segment")
  func pathComponents() throws {
    #expect(try url(SegmentRequest(segments: ["files", "a/b.txt"])) == "https://api.example.com/v1/files/a%2Fb.txt")
    #expect(try url(SegmentRequest(segments: ["files", "a%2Fb"])) == "https://api.example.com/v1/files/a%252Fb")
    #expect(try url(SegmentRequest(segments: ["", "q?x#y", ""])) == "https://api.example.com/v1/q%3Fx%23y")
    expectInvalid(SegmentRequest(segments: ["users", ".."]))
  }

  @Test("The default path components split the path")
  func defaultPathComponents() {
    #expect(Request(path: "/a//b/").pathComponents == ["a", "b"])
  }

  @Test("The environment path is kept as it is percent-encoded")
  func environmentEncodedPath() throws {
    let environment = HTTPEnvironment(authority: "api.example.com").setPercentEncodedPath("/v1/a%2Fb")
    #expect(try url(Request(environment: environment, path: "items")) == "https://api.example.com/v1/a%2Fb/items")
  }

  // MARK: Query

  @Test("Query names and values encode +, &, = and ;")
  func queryEncoding() throws {
    let request = Request(path: "search", queryItems: [
      URLQueryItem(name: "email", value: "a+tag@example.com"),
      URLQueryItem(name: "q", value: "a&admin=true;x"),
      URLQueryItem(name: "a b", value: "c d"),
      URLQueryItem(name: "flag", value: nil),
      URLQueryItem(name: "empty", value: "")
    ])
    #expect(try url(request) == "https://api.example.com/v1/search?email=a%2Btag@example.com&q=a%26admin%3Dtrue%3Bx&a%20b=c%20d&flag&empty=")
    let items = try #require(URLComponents(url: request.url, resolvingAgainstBaseURL: false)?.queryItems)
    #expect(items.first { $0.name == "email" }?.value == "a+tag@example.com")
    #expect(items.first { $0.name == "q" }?.value == "a&admin=true;x")
  }

  @Test("The environment query is kept as it is percent-encoded, and items are appended")
  func environmentQuery() throws {
    let environment = HTTPEnvironment(authority: "api.example.com").setPercentEncodedQuery("sig=abc%2Bdef")
    #expect(try url(Request(environment: environment, path: "items")) == "https://api.example.com/items?sig=abc%2Bdef")
    let withItems = Request(environment: environment, path: "items", queryItems: [URLQueryItem(name: "page", value: "2")])
    #expect(try url(withItems) == "https://api.example.com/items?sig=abc%2Bdef&page=2")
  }

  @Test("No query is added when there are no items")
  func emptyQuery() throws {
    #expect(try url(Request(environment: #require(HTTPEnvironment(string: "https://api.example.com/v1?")), path: "items")) == "https://api.example.com/v1/items")
  }

  // MARK: HTTPEnvironment query helpers

  @Test("Environment query helpers encode + and keep the existing query")
  func environmentQueryHelpers() {
    let environment = HTTPEnvironment(authority: "api.example.com")
    #expect(environment.setQueryItems([URLQueryItem(name: "phone", value: "+15551234")]).percentEncodedQuery == "phone=%2B15551234")
    let signed = environment.setPercentEncodedQuery("sig=abc%2Bdef")
    #expect(signed.appendQueryItems([URLQueryItem(name: "page", value: "2")]).percentEncodedQuery == "sig=abc%2Bdef&page=2")
    #expect(signed.appendQueryItems([URLQueryItem]()).percentEncodedQuery == "sig=abc%2Bdef")
    #expect(environment.appendQueryItems([URLQueryItem(name: "a", value: "1")]).percentEncodedQuery == "a=1")
  }
}
