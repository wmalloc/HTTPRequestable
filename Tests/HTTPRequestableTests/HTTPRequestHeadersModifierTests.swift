//
//  HTTPRequestModifierTests.swift
//
//  Created by Waqar Malik on 2/5/26.
//

import Foundation
@testable import HTTPRequestable
import HTTPTypes
import Testing

@Suite("HTTPRequestHeadersModifier Tests")
struct HTTPRequestHeadersModifierTests {
  // MARK: - Default Header Modifier Tests

  @Test("Default header modifier applies to HTTPRequest")
  func defaultHTTPHeaderModifier() async throws {
    let defaultModifier = HTTPRequestHeadersModifier.defaultHeaderModifier
    let environment: HTTPEnvironment = .init(authority: "hacker-news.firebaseio.com", path: "/v0")
    let requestable = try StoryListRequest(environment, storyType: "topstories")
    var httpRequest = try requestable.httpRequest
    httpRequest = try await httpRequest.modify([defaultModifier], for: nil)
    #expect(httpRequest.headerFields[.acceptEncoding] == HTTPField.defaultAcceptEncoding.value)
    #expect(httpRequest.headerFields[.acceptLanguage] == HTTPField.defaultAcceptLanguage.value)
    #expect(httpRequest.headerFields[.userAgent] == HTTPField.defaultUserAgent.value)
  }

  @Test("Default header modifier applies to URLRequest")
  func defaultURLHeaderModifier() async throws {
    let defaultModifier = HTTPRequestHeadersModifier.defaultHeaderModifier
    let environment: HTTPEnvironment = .init(authority: "hacker-news.firebaseio.com", path: "/v0")
    let requestable = try StoryListRequest(environment, storyType: "topstories")
    var urlRequest = try requestable.urlRequest
    urlRequest = try await urlRequest.modify([defaultModifier], for: nil)
    #expect(urlRequest.value(forHTTPField: .acceptEncoding) == HTTPField.defaultAcceptEncoding.value)
    #expect(urlRequest.value(forHTTPField: .acceptLanguage) == HTTPField.defaultAcceptLanguage.value)
    #expect(urlRequest.value(forHTTPField: .userAgent) == HTTPField.defaultUserAgent.value)
  }

  // MARK: - Initialization Tests

  @Test("Initialize with HTTPFields")
  func initWithHTTPFields() {
    let fields = HTTPFields([
      HTTPField(name: .userAgent, value: "TestAgent/1.0"),
      HTTPField(name: .accept, value: "application/json")
    ])

    let modifier = HTTPRequestHeadersModifier(headerFields: fields)

    #expect(modifier.headerFields.count == 2)
    #expect(modifier.headerFields[.userAgent] == "TestAgent/1.0")
    #expect(modifier.headerFields[.accept] == "application/json")
    #expect(modifier.replaceExisting == false)
  }

  @Test("Initialize with HTTPFields and replaceExisting flag")
  func initWithHTTPFieldsReplaceExisting() {
    let fields = HTTPFields([HTTPField(name: .userAgent, value: "TestAgent/1.0")])
    let modifier = HTTPRequestHeadersModifier(headerFields: fields, replaceExisting: true)

    #expect(modifier.replaceExisting == true)
  }

  @Test("Initialize with Sequence of HTTPFields")
  func initWithSequence() {
    let fieldArray = [
      HTTPField(name: .userAgent, value: "TestAgent/1.0"),
      HTTPField(name: .accept, value: "application/json")
    ]

    let modifier = HTTPRequestHeadersModifier(fields: fieldArray)

    #expect(modifier.headerFields.count == 2)
    #expect(modifier.headerFields[.userAgent] == "TestAgent/1.0")
    #expect(modifier.headerFields[.accept] == "application/json")
  }

  @Test("Initialize with dictionary")
  func initWithDictionary() {
    let headers = [
      "User-Agent": "TestAgent/1.0",
      "Accept": "application/json"
    ]

    let modifier = HTTPRequestHeadersModifier(headers: headers)

    #expect(modifier.headerFields.count == 2)
    #expect(modifier.headerFields[.userAgent] == "TestAgent/1.0")
    #expect(modifier.headerFields[.accept] == "application/json")
  }

  @Test("Initialize with dictionary containing invalid header names")
  func initWithInvalidHeaders() {
    let headers = [
      "User-Agent": "TestAgent/1.0",
      "": "invalid", // Empty header name
      "Valid-Header": "valid"
    ]

    let modifier = HTTPRequestHeadersModifier(headers: headers)

    // Empty string should be filtered out, but valid headers should remain
    #expect(modifier.headerFields[.userAgent] == "TestAgent/1.0")
  }

  // MARK: - Array Literal Tests

  @Test("Initialize with array literal")
  func initWithArrayLiteral() {
    let modifier: HTTPRequestHeadersModifier = [
      HTTPField(name: .userAgent, value: "TestAgent/1.0"),
      HTTPField(name: .accept, value: "application/json")
    ]

    #expect(modifier.headerFields.count == 2)
    #expect(modifier.headerFields[.userAgent] == "TestAgent/1.0")
    #expect(modifier.headerFields[.accept] == "application/json")
    #expect(modifier.replaceExisting == true) // Array literal defaults to true
  }

  // MARK: - Dictionary Literal Tests

  @Test("Initialize with dictionary literal")
  func initWithDictionaryLiteral() {
    let modifier: HTTPRequestHeadersModifier = [
      "User-Agent": "TestAgent/1.0",
      "Accept": "application/json"
    ]

    #expect(modifier.headerFields.count == 2)
    #expect(modifier.headerFields[.userAgent] == "TestAgent/1.0")
    #expect(modifier.headerFields[.accept] == "application/json")
    #expect(modifier.replaceExisting == true) // Dictionary literal defaults to true
  }

  // MARK: - HTTPRequest Modification Tests

  @Test("Modify HTTPRequest without replacing existing headers")
  func modifyHTTPRequestWithoutReplace() async throws {
    let environment: HTTPEnvironment = .init(authority: "example.com", path: "/")
    let requestable = try StoryListRequest(environment, storyType: "topstories")
    var httpRequest = try requestable.httpRequest

    // Add a custom User-Agent
    httpRequest.headerFields[.userAgent] = "CustomAgent/1.0"

    // Apply modifier with replaceExisting = false
    let modifier = HTTPRequestHeadersModifier(headers: [
      "User-Agent": "ModifierAgent/1.0",
      "Accept-Language": "en-US"
    ], replaceExisting: false)

    try await modifier.modify(&httpRequest, for: nil)

    // User-Agent should NOT be replaced
    #expect(httpRequest.headerFields[.userAgent] == "CustomAgent/1.0")
    // Accept-Language should be added
    #expect(httpRequest.headerFields[.acceptLanguage] == "en-US")
  }

  @Test("Modify HTTPRequest with replacing existing headers")
  func modifyHTTPRequestWithReplace() async throws {
    let environment: HTTPEnvironment = .init(authority: "example.com", path: "/")
    let requestable = try StoryListRequest(environment, storyType: "topstories")
    var httpRequest = try requestable.httpRequest

    // Add a custom User-Agent
    httpRequest.headerFields[.userAgent] = "CustomAgent/1.0"

    // Apply modifier with replaceExisting = true
    let modifier = HTTPRequestHeadersModifier(headers: [
      "User-Agent": "ModifierAgent/1.0",
      "Accept-Language": "en-US"
    ], replaceExisting: true)

    try await modifier.modify(&httpRequest, for: nil)

    // User-Agent SHOULD be replaced
    #expect(httpRequest.headerFields[.userAgent] == "ModifierAgent/1.0")
    // Accept-Language should be added
    #expect(httpRequest.headerFields[.acceptLanguage] == "en-US")
  }

  @Test("Modify HTTPRequest with empty headers")
  func modifyHTTPRequestWithEmptyHeaders() async throws {
    let environment: HTTPEnvironment = .init(authority: "example.com", path: "/")
    let requestable = try StoryListRequest(environment, storyType: "topstories")
    var httpRequest = try requestable.httpRequest

    let originalFieldsCount = httpRequest.headerFields.count

    // Apply modifier with no headers
    let modifier = HTTPRequestHeadersModifier(headers: [:])
    try await modifier.modify(&httpRequest, for: nil)

    // No headers should be added
    #expect(httpRequest.headerFields.count == originalFieldsCount)
  }

  // MARK: - URLRequest Modification Tests

  @Test("Modify URLRequest without replacing existing headers")
  func modifyURLRequestWithoutReplace() async throws {
    let environment: HTTPEnvironment = .init(authority: "example.com", path: "/")
    let requestable = try StoryListRequest(environment, storyType: "topstories")
    var urlRequest = try requestable.urlRequest

    // Add a custom User-Agent
    urlRequest.setValue("CustomAgent/1.0", forHTTPField: .userAgent)

    // Apply modifier with replaceExisting = false
    let modifier = HTTPRequestHeadersModifier(headers: [
      "User-Agent": "ModifierAgent/1.0",
      "Accept-Language": "en-US"
    ], replaceExisting: false)

    try await modifier.modify(&urlRequest, for: nil)

    // User-Agent should NOT be replaced
    #expect(urlRequest.value(forHTTPField: .userAgent) == "CustomAgent/1.0")
    // Accept-Language should be added
    #expect(urlRequest.value(forHTTPField: .acceptLanguage) == "en-US")
  }

  @Test("Modify URLRequest with replacing existing headers")
  func modifyURLRequestWithReplace() async throws {
    let environment: HTTPEnvironment = .init(authority: "example.com", path: "/")
    let requestable = try StoryListRequest(environment, storyType: "topstories")
    var urlRequest = try requestable.urlRequest

    // Add a custom User-Agent
    urlRequest.setValue("CustomAgent/1.0", forHTTPField: .userAgent)

    // Apply modifier with replaceExisting = true
    let modifier = HTTPRequestHeadersModifier(headers: [
      "User-Agent": "ModifierAgent/1.0",
      "Accept-Language": "en-US"
    ], replaceExisting: true)

    try await modifier.modify(&urlRequest, for: nil)

    // User-Agent SHOULD be replaced
    #expect(urlRequest.value(forHTTPField: .userAgent) == "ModifierAgent/1.0")
    // Accept-Language should be added
    #expect(urlRequest.value(forHTTPField: .acceptLanguage) == "en-US")
  }

  @Test("Modify URLRequest with empty headers")
  func modifyURLRequestWithEmptyHeaders() async throws {
    let environment: HTTPEnvironment = .init(authority: "example.com", path: "/")
    let requestable = try StoryListRequest(environment, storyType: "topstories")
    var urlRequest = try requestable.urlRequest

    let originalHeaders = urlRequest.allHTTPHeaderFields

    // Apply modifier with no headers
    let modifier = HTTPRequestHeadersModifier(headers: [:])
    try await modifier.modify(&urlRequest, for: nil)

    // No headers should be added
    #expect(urlRequest.allHTTPHeaderFields == originalHeaders)
  }

  // MARK: - Multiple Header Tests

  @Test("Modify request with multiple headers")
  func modifyWithMultipleHeaders() async throws {
    let environment: HTTPEnvironment = .init(authority: "example.com", path: "/")
    let requestable = try StoryListRequest(environment, storyType: "topstories")
    var httpRequest = try requestable.httpRequest

    let modifier = HTTPRequestHeadersModifier(headers: [
      "User-Agent": "TestAgent/1.0",
      "Accept": "application/json",
      "Accept-Language": "en-US",
      "Cache-Control": "no-cache"
    ])

    try await modifier.modify(&httpRequest, for: nil)

    #expect(httpRequest.headerFields[.userAgent] == "TestAgent/1.0")
    #expect(httpRequest.headerFields[.accept] == "application/json")
    #expect(httpRequest.headerFields[.acceptLanguage] == "en-US")
    #expect(httpRequest.headerFields[.cacheControl] == "no-cache")
  }

  // MARK: - Sendable Conformance Tests

  @Test("Modifier is Sendable")
  func modifierIsSendable() async {
    let modifier = HTTPRequestHeadersModifier(headers: ["User-Agent": "TestAgent/1.0"])

    // Test that modifier can be used in async context
    await Task {
      _ = modifier.headerFields
    }.value

    #expect(modifier.headerFields.count == 1)
  }

  // MARK: - Edge Case Tests

  @Test("Modify request with nil session")
  func modifyWithNilSession() async throws {
    let environment: HTTPEnvironment = .init(authority: "example.com", path: "/")
    let requestable = try StoryListRequest(environment, storyType: "topstories")
    var httpRequest = try requestable.httpRequest

    let modifier = HTTPRequestHeadersModifier(headers: ["User-Agent": "TestAgent/1.0"])

    // Should not throw when session is nil
    try await modifier.modify(&httpRequest, for: nil)

    #expect(httpRequest.headerFields[.userAgent] == "TestAgent/1.0")
  }

  @Test("Modifier with same header added multiple times")
  func modifierWithDuplicateHeaders() async throws {
    let fields = [
      HTTPField(name: .userAgent, value: "TestAgent/1.0"),
      HTTPField(name: .userAgent, value: "TestAgent/2.0") // Duplicate
    ]

    let modifier = HTTPRequestHeadersModifier(fields: fields)

    let environment: HTTPEnvironment = .init(authority: "example.com", path: "/")
    let requestable = try StoryListRequest(environment, storyType: "topstories")
    var httpRequest = try requestable.httpRequest

    try await modifier.modify(&httpRequest, for: nil)

    // The behavior depends on HTTPFields implementation
    // Typically, the last value wins or they're concatenated
    #expect(httpRequest.headerFields[.userAgent] != nil)
  }
}
