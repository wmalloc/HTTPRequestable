//
//  HTTPFieldNameMacroUsageTests.swift
//
//  Created by Waqar Malik on 11/25/26.
//

import HTTPRequestable
import HTTPTypes
import MockURLProtocol
import Testing

private extension HTTPField.Name {
  static let requestID = #HTTPFieldName("X-Request-ID")
}

/// Uses `#HTTPFieldName` through the compiler and the real plugin, so the declaration and its expansion
/// are checked as clients see them.
struct HTTPFieldNameMacroUsageTests {
  @Test("#HTTPFieldName produces the name of its literal, keeping its case")
  func producesName() {
    let name = #HTTPFieldName("X-Request-ID")
    #expect(name.rawName == "X-Request-ID")
    #expect(name.canonicalName == "x-request-id")
    #expect(name == .requestID)
    #expect(#HTTPFieldName("content-type") == .contentType)
  }

  @Test("#HTTPFieldName works where a field name is expected")
  func usableAsName() {
    var fields: HTTPFields = [.requestID: "abc"]
    fields[#HTTPFieldName("X-API-Key")] = "key"
    #expect(fields[#HTTPFieldName("x-request-id")] == "abc")
    #expect(fields[HTTPField.Name("X-API-Key")!] == "key")
  }

  @Test("Names built with #HTTPFieldName keep their spelling")
  func builtInNames() {
    #expect(HTTPField.Name.xMockIdentifier.rawName == "X-Mock-Identifier")
    #expect(String.xMockIdentifier == "X-Mock-Identifier")
    #expect(HTTPRedirectPolicy.defaultSensitiveHeaders.contains(HTTPField.Name("x-api-key")!))
  }
}
