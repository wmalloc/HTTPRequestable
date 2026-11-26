//
//  URLMacroUsageTests.swift
//
//  Created by Waqar Malik on 11/24/26.
//

import Foundation
import HTTPRequestable
import Testing

/// Uses `#URL` through the compiler and the real plugin, so the declaration and its expansion are
/// checked as clients see them.
struct URLMacroUsageTests {
  @Test("#URL produces the URL of its literal")
  func producesURL() {
    let url = #URL("https://api.example.com:8443/v1/items?q=a%20b")
    #expect(url.scheme == "https")
    #expect(url.host() == "api.example.com")
    #expect(url.port == 8443)
    #expect(url.path() == "/v1/items")
    #expect(url.query(percentEncoded: true) == "q=a%20b")
  }

  @Test("#URL works where a URL is expected")
  func usableAsURL() throws {
    let request = URLRequest(url: #URL("https://api.example.com/v1"))
    #expect(request.url?.absoluteString == "https://api.example.com/v1")
    let httpRequest = try #URL("https://api.example.com/v1").absoluteString.httpRequest
    #expect(httpRequest.authority == "api.example.com")
  }
}
