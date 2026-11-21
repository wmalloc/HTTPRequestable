//
//  HTTPRedirectPolicyTests.swift
//

import Foundation
import HTTPTypes
@testable import HTTPRequestable
import Testing

struct HTTPRedirectPolicyTests {
  private func request(_ url: String) throws -> URLRequest {
    var request = try URLRequest(url: #require(URL(string: url)))
    request.setValue("Bearer secret", forHTTPHeaderField: "Authorization")
    request.setValue("session=1", forHTTPHeaderField: "Cookie")
    request.setValue("key", forHTTPHeaderField: "X-API-Key")
    request.setValue("keep", forHTTPHeaderField: "Accept")
    return request
  }

  @Test("Same-origin redirects keep all headers")
  func sameOriginKeepsHeaders() throws {
    let result = try #require(HTTPRedirectPolicy().redirectedRequest(request("https://api.example.com/b"), from: URL(string: "https://api.example.com/a")))
    #expect(result.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
    #expect(result.value(forHTTPHeaderField: "Cookie") == "session=1")
  }

  @Test("Cross-host redirects strip credential headers only")
  func crossHostStripsCredentials() throws {
    let result = try #require(HTTPRedirectPolicy().redirectedRequest(request("https://other.example.org/b"), from: URL(string: "https://api.example.com/a")))
    #expect(result.value(forHTTPHeaderField: "Authorization") == nil)
    #expect(result.value(forHTTPHeaderField: "Cookie") == nil)
    #expect(result.value(forHTTPHeaderField: "X-API-Key") == nil)
    #expect(result.value(forHTTPHeaderField: "Accept") == "keep")
  }

  @Test("A different port is a different origin")
  func differentPortStripsCredentials() throws {
    let result = try #require(HTTPRedirectPolicy().redirectedRequest(request("https://api.example.com:8443/b"), from: URL(string: "https://api.example.com/a")))
    #expect(result.value(forHTTPHeaderField: "Authorization") == nil)
  }

  @Test("https to http is blocked unless allowed")
  func downgradeBlocked() throws {
    let from = URL(string: "https://api.example.com/a")
    #expect(try HTTPRedirectPolicy().redirectedRequest(request("http://api.example.com/b"), from: from) == nil)
    #expect(try HTTPRedirectPolicy(blocksDowngrade: false).redirectedRequest(request("http://api.example.com/b"), from: from) != nil)
  }

  @Test("Redirects to hosts outside allowedHosts are not followed")
  func allowedHostsEnforced() throws {
    let policy = HTTPRedirectPolicy(allowedHosts: ["API.example.com"])
    let from = URL(string: "https://api.example.com/a")
    #expect(try policy.redirectedRequest(request("https://api.example.com/b"), from: from) != nil)
    #expect(try policy.redirectedRequest(request("https://evil.example.org/b"), from: from) == nil)
  }
}
