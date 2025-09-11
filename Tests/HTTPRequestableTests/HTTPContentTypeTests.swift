//
//  HTTPContentTypeTests.swift
//
//  Created by Waqar Malik on 9/6/25.
//

import Foundation
@testable import HTTPRequestable // Replace with actual module name if different
import Testing

@Suite("HTTPContentType")
struct HTTPContentTypeTests {
  @Test("Initializes and trims whitespace")
  func initTrimsWhitespace() async throws {
    let contentType = HTTPContentType(rawValue: "  application/json  ")
    #expect(contentType.rawValue == "application/json")
  }

  @Test("Extracts mimeType correctly")
  func testMimeType() async throws {
    let contentType = HTTPContentType(rawValue: "text/html; charset=utf-8")
    #expect(contentType.mimeType == "text/html")
    let singleType = HTTPContentType(rawValue: "image/png")
    #expect(singleType.mimeType == "image/png")
  }

  @Test("Parses multiple content types")
  func contentTypesParsing() async throws {
    let parsed = HTTPContentType.contentTypes(for: "application/json, text/html; charset=utf-8 ,image/png")
    #expect(parsed.count == 3)
    #expect(parsed[0].rawValue == "application/json")
    #expect(parsed[1].rawValue == "text/html; charset=utf-8")
    #expect(parsed[2].rawValue == "image/png")
  }

  @Test("Empty string returns empty array for contentTypes(for:)")
  func contentTypesForEmptyString() async throws {
    #expect(HTTPContentType.contentTypes(for: "").isEmpty)
  }

  @Test("StringLiteral and LosslessStringConvertible init")
  func stringLiteralAndLosslessInit() async throws {
    let literal: HTTPContentType = "text/css"
    #expect(literal.rawValue == "text/css")
    let lossless = HTTPContentType("text/html")
    #expect(lossless.rawValue == "text/html")
  }

  @Test("description returns rawValue")
  func testDescription() async throws {
    let ctype = HTTPContentType(rawValue: "image/svg+xml")
    #expect(ctype.description == "image/svg+xml")
  }

  @Test("playgroundDescription returns description")
  func testPlaygroundDescription() async throws {
    let ctype = HTTPContentType(rawValue: "image/svg+xml")
    #expect(String(describing: ctype.playgroundDescription) == "image/svg+xml")
  }

  @Test("Identifiable conformance")
  func testId() async throws {
    let ctype = HTTPContentType(rawValue: "application/xml")
    #expect(ctype.id == "application/xml")
  }

  @Test("Encodable and Decodable round trip")
  func codable() async throws {
    let ctype = HTTPContentType(rawValue: "application/json")
    let data = try JSONEncoder().encode(ctype)
    let decoded = try JSONDecoder().decode(HTTPContentType.self, from: data)
    #expect(decoded == ctype)
  }

  @Test("Comparing with string literal")
  func equalsStringLiteral() async throws {
    let ctype: HTTPContentType = "application/json"
    #expect(ctype == "application/json")
    #expect(!(ctype == "text/html"))
  }

  @Test("Static content types are correct")
  func staticContentTypes() async throws {
    #expect(HTTPContentType.any.rawValue == "*/*")
    #expect(HTTPContentType.css.rawValue == "text/css")
    #expect(HTTPContentType.formData.rawValue == "form-data")
    #expect(HTTPContentType.formEncoded.rawValue == "application/x-www-form-urlencoded")
    #expect(HTTPContentType.gif.rawValue == "image/gif")
    #expect(HTTPContentType.html.rawValue == "text/html")
    #expect(HTTPContentType.jpeg.rawValue == "image/jpeg")
    #expect(HTTPContentType.json.rawValue == "application/json")
    #expect(HTTPContentType.jsonUTF8.rawValue == "application/json; charset=utf-8")
    #expect(HTTPContentType.multipartForm.rawValue == "multipart/form-data")
    #expect(HTTPContentType.octetStream.rawValue == "application/octet-stream")
    #expect(HTTPContentType.patchjson.rawValue == "application/json-patch+json")
    #expect(HTTPContentType.png.rawValue == "image/png")
    #expect(HTTPContentType.svg.rawValue == "image/svg+xml")
    #expect(HTTPContentType.textPlain.rawValue == "text/plain")
    #expect(HTTPContentType.xml.rawValue == "application/xml")
  }

  @Test("Hashable and Sendable conformances are valid")
  func hashableSendable() async throws {
    let set: Set<HTTPContentType> = ["application/json", "text/html", "image/png"]
    #expect(set.contains(HTTPContentType(rawValue: "application/json")))
  }
}
