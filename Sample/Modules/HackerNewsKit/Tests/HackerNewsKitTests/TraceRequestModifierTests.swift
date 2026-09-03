//
//  TraceRequestModifierTests.swift
//
//  Created by Waqar Malik on 8/27/26.
//

import Foundation
@testable import HackerNewsKit
import HTTPRequestable
import HTTPTypes
import Testing

@Suite("TraceRequestModifier")
struct TraceRequestModifierTests {
  private func makeRequest() -> HTTPRequest {
    HTTPRequest(method: .get, scheme: "https", authority: "hacker-news.firebaseio.com", path: "/v0/topstories.json")
  }

  @Test("Trace header names")
  func headerNames() {
    #expect(HTTPField.Name.xTraceId.rawName == "X-Trace-Id")
    #expect(HTTPField.Name.xRequestId.rawName == "X-Request-Id")
    #expect(HTTPField.Name.xCorrelationId.rawName == "X-Correlation-Id")
    #expect(HTTPField.Name.xTraceId.canonicalName == "x-trace-id")
    #expect(HTTPField.Name.xRequestId.canonicalName == "x-request-id")
    #expect(HTTPField.Name.xCorrelationId.canonicalName == "x-correlation-id")
  }

  @Test("Defaults to the X-Trace-Id header")
  func defaultHeaderField() {
    #expect(TraceRequestModifier.default.headerField == .xTraceId)
    #expect(TraceRequestModifier().headerField == .xTraceId)
  }

  @Test("Default generator produces unique UUID strings")
  func defaultGeneratorIsUnique() {
    let modifier = TraceRequestModifier()
    let ids = (0 ..< 100).map { _ in modifier.generator() }
    #expect(Set(ids).count == 100)
    #expect(ids.allSatisfy { UUID(uuidString: $0) != nil })
  }

  @Test("Sets the trace header on an HTTPRequest")
  func modifiesHTTPRequest() async throws {
    let modifier = TraceRequestModifier(idGenerator: { "trace-1" })
    var request = makeRequest()
    #expect(request.headerFields[.xTraceId] == nil)

    try await modifier.modify(&request, for: nil)
    #expect(request.headerFields[.xTraceId] == "trace-1")
  }

  @Test("Sets the trace header on a URLRequest")
  func modifiesURLRequest() async throws {
    let modifier = TraceRequestModifier(idGenerator: { "trace-2" })
    var request = try URLRequest(url: #require(URL(string: "https://hacker-news.firebaseio.com/v0/topstories.json")))

    try await modifier.modify(&request, for: nil)
    #expect(request.value(forHTTPHeaderField: "X-Trace-Id") == "trace-2")
  }

  @Test("Honours a custom header field")
  func customHeaderField() async throws {
    let modifier = TraceRequestModifier(headerField: .xCorrelationId, idGenerator: { "correlation-1" })
    var request = makeRequest()

    try await modifier.modify(&request, for: nil)
    #expect(request.headerFields[.xCorrelationId] == "correlation-1")
    #expect(request.headerFields[.xTraceId] == nil)
  }

  @Test("Generates a fresh identifier for every request")
  func identifierIsPerRequest() async throws {
    let modifier = TraceRequestModifier()
    var first = makeRequest()
    var second = makeRequest()

    try await modifier.modify(&first, for: nil)
    try await modifier.modify(&second, for: nil)

    let firstID = try #require(first.headerFields[.xTraceId])
    let secondID = try #require(second.headerFields[.xTraceId])
    #expect(firstID != secondID)
  }

  @Test("Replaces an identifier left over from a previous pass")
  func overwritesExistingIdentifier() async throws {
    let modifier = TraceRequestModifier(idGenerator: { "trace-new" })
    var request = makeRequest()
    request.headerFields[.xTraceId] = "trace-old"

    try await modifier.modify(&request, for: nil)
    #expect(request.headerFields[.xTraceId] == "trace-new")
  }

  @Test("Leaves the rest of the request untouched")
  func preservesOtherFields() async throws {
    let modifier = TraceRequestModifier(idGenerator: { "trace-3" })
    var request = makeRequest()
    request.headerFields[.accept] = "application/json"

    try await modifier.modify(&request, for: nil)
    #expect(request.headerFields[.accept] == "application/json")
    #expect(request.method == .get)
    #expect(request.path == "/v0/topstories.json")
  }
}
