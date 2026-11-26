//
//  MockURLProtocolTests.swift
//
//  Created by Waqar Malik on 11/25/26.
//

import Foundation
import HTTPRequestable
import MockURLProtocol
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct MockURLProtocolTests {
  private let session: URLSession = {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: configuration)
  }()

  /// A request with a path nobody else stubs, so parallel tests cannot take its handler.
  private func uniqueRequest() throws -> StoryListRequest {
    try StoryListRequest(HTTPEnvironment(authority: "api.example.com", path: "/v1"), storyType: UUID().uuidString)
  }

  private func handler(body: String) -> MockURLRequestHandler {
    { request in
      (Data(body.utf8), HTTPURLResponse.ok(url: request.url!))
    }
  }

  @Test("forRequest: keys the handler by the X-Mock-Identifier header when it is set")
  func forRequestUsesHeader() async throws {
    let request = try uniqueRequest().byAddingMockIdentifierHeader()
    try await MockURLProtocol.setRequestHandler(handler(body: "header"), forRequest: request)
    let response = try await session.performRequest(request)
    #expect(String(decoding: response.responseData, as: UTF8.self) == "header")
  }

  @Test("forRequest: keys the handler by the URL when no X-Mock-Identifier header is set")
  func forRequestFallsBackToURL() async throws {
    let request = try uniqueRequest()
    #expect(request.mockIdentifier == nil)
    try await MockURLProtocol.setRequestHandler(handler(body: "url"), forRequest: request)
    let response = try await session.performRequest(request)
    #expect(String(decoding: response.responseData, as: UTF8.self) == "url")
  }

  @Test("forRequest: and forIdentifier: with the request's URL register the same handler")
  func forRequestMatchesForIdentifier() async throws {
    let request = try uniqueRequest()
    try await MockURLProtocol.setRequestHandler(handler(body: "first"), forRequest: request)
    try await MockURLProtocol.setRequestHandler(handler(body: "second"), forIdentifier: request.url)
    let response = try await session.performRequest(request)
    #expect(String(decoding: response.responseData, as: UTF8.self) == "second")
  }

  @Test("forRequest: throws when the request has no header and no valid URL")
  func forRequestWithoutIdentifierThrows() async throws {
    let request = try StoryListRequest(HTTPEnvironment(), storyType: "topstories")
    await #expect(throws: URLError(.badURL)) {
      try await MockURLProtocol.setRequestHandler(handler(body: ""), forRequest: request)
    }
  }

  @Test("A custom MockRequestKey keys the handler by its mock identifier")
  func customKey() async throws {
    let request = try uniqueRequest()
    try await MockURLProtocol.setRequestHandler(handler(body: "custom"), forIdentifier: CustomKey(url: request.url))
    let response = try await session.performRequest(request)
    #expect(String(decoding: response.responseData, as: UTF8.self) == "custom")
  }

  @Test("forIdentifier: keys the handler by a URL")
  func forIdentifierUsesURL() async throws {
    let request = try uniqueRequest()
    try await MockURLProtocol.setRequestHandler(handler(body: "identifier"), forIdentifier: request.url)
    let response = try await session.performRequest(request)
    #expect(String(decoding: response.responseData, as: UTF8.self) == "identifier")
  }
}

private struct CustomKey: MockRequestKey {
  let url: URL
  var mockIdentifier: String? {
    url.absoluteString
  }
}
