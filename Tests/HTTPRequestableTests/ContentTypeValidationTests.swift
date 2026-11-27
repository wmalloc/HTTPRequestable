//
//  ContentTypeValidationTests.swift
//
//  Created by Waqar Malik on 11/25/26.
//

import Foundation
@testable import HTTPRequestable
import HTTPTypes
import Testing

struct ContentTypeParsingTests {
  @Test("Valid media types are parsed into type, subtype and parameters")
  func parsesParts() throws {
    let contentType = try #require(HTTPContentType(rawValue: #"Text/HTML; Charset=UTF-8; title="a \"b\", c""#))
    #expect(contentType.type == "text")
    #expect(contentType.subtype == "html")
    #expect(contentType.parameters == ["charset": "UTF-8", "title": #"a "b", c"#])
    #expect(contentType.rawValue == #"Text/HTML; Charset=UTF-8; title="a \"b\", c""#)
  }

  @Test("Valid media types are accepted", arguments: [
    "application/json", "*/*", "text/*", "image/svg+xml", "application/vnd.api+json",
    "text/plain;", "text/plain; ; charset=utf-8", "text/plain;charset=utf-8", "text/plain \t; charset=utf-8",
    "multipart/form-data; boundary=\"a b:c\"", "text/plain; name=\"ä\""
  ])
  func valid(value: String) {
    #expect(HTTPContentType(rawValue: value) != nil)
  }

  @Test("Invalid media types are rejected", arguments: [
    "", "json", "/json", "application/", "a/b/c", "a b/c", "text/html extra", "text/html; charset",
    "text/html; charset =utf-8", "text/html; charset= utf-8", "text/html; =utf-8", "text/html; a=\"unclosed",
    "application/json\r\nX-Evil: 1", "text/html; a=\"x\r\ny\"", "text/html; a=b c", "ä/b",
    "text/html; charset=utf-8; charset=latin1", "text/html; a=1; A=2",
  ])
  func invalid(value: String) {
    #expect(HTTPContentType(rawValue: value) == nil)
    #expect(HTTPContentType(value as String) == nil)
  }

  @Test("Equality ignores the case of type, subtype, parameter names and charset")
  func equality() {
    let base: HTTPContentType = "application/json; charset=utf-8"
    #expect(base == "Application/JSON; Charset=UTF-8")
    #expect(base == "application/json;charset=utf-8")
    #expect(base != "application/json")
    #expect(HTTPContentType("text/plain; format=Flowed") != HTTPContentType("text/plain; format=flowed"))
    #expect(Set<HTTPContentType>(["text/html", "TEXT/HTML"]).count == 1)
  }

  @Test("Media ranges match by type and subtype, ignoring parameters")
  func matching() {
    let json: HTTPContentType = "application/json; charset=utf-8"
    #expect(HTTPContentType.json.matches(json))
    #expect(HTTPContentType("Application/JSON").matches(json))
    #expect(HTTPContentType.any.matches(json))
    #expect(HTTPContentType("application/*").matches(json))
    #expect(!HTTPContentType("text/*").matches(json))
    #expect(!HTTPContentType.xml.matches(json))
    #expect(!HTTPContentType("*/json").matches(json))
  }

  @Test("Lists split only on commas outside quotes, and leave out invalid entries")
  func lists() {
    let parsed = HTTPContentType.contentTypes(for: #"text/plain; a="x,y", bad entry, application/json"#)
    #expect(parsed.map(\.rawValue) == [#"text/plain; a="x,y""#, "application/json"])
  }

  @Test("Decoding rejects invalid media types without repeating them")
  func decoding() throws {
    let decoder = JSONDecoder()
    #expect(try decoder.decode(HTTPContentType.self, from: Data(#""text/html""#.utf8)) == .html)
    let error = #expect(throws: DecodingError.self) {
      try decoder.decode(HTTPContentType.self, from: Data(#""s3cret value""#.utf8))
    }
    #expect(error.map { String(describing: $0) }?.contains("s3cret") == false)
  }

  #if os(macOS) || os(Linux)
  @Test("Invalid literals stop the process")
  func invalidLiteralTraps() async {
    await #expect(processExitsWith: .failure) {
      _ = HTTPContentType(stringLiteral: "not a type")
    }
  }
  #endif

  @Test("All predefined content types are valid")
  func predefined() {
    let all: [HTTPContentType] = [.any, .css, .csv, .formEncoded, .gif, .heic, .html, .javascript, .jpeg, .json, .jsonUTF8,
                                  .m4a, .mp3, .mp4, .multipartForm, .octetStream, .patchjson, .pdf, .png, .quickTime,
                                  .svg, .textPlain, .webp, .xml, .zip]
    #expect(all.allSatisfy { HTTPContentType(rawValue: $0.rawValue) == $0 })
  }
}

/// Expects `body` to throw an `HTTPError` that `matches` accepts. `HTTPError` is not `Equatable`, so
/// cases are matched with a pattern.
private func expectHTTPError(_ matches: (HTTPError) -> Bool, sourceLocation: SourceLocation = #_sourceLocation,
                             _ body: () throws -> Void) {
  let error = #expect(throws: HTTPError.self, sourceLocation: sourceLocation) {
    try body()
  }
  #expect(error.map(matches) == true, sourceLocation: sourceLocation)
}

private func isInvalidContentType(_ error: HTTPError) -> Bool {
  if case .invalidContentType = error {
    true
  } else {
    false
  }
}

private func isContentTypeHeaderMissing(_ error: HTTPError) -> Bool {
  if case .contentTypeHeaderMissing = error {
    true
  } else {
    false
  }
}

struct ContentTypeHeaderTests {
  private func request(accept: String?) -> HTTPRequest {
    var request = HTTPRequest(method: .get, url: URL(string: "https://api.example.com/items")!)
    request.headerFields[.accept] = accept
    return request
  }

  private func response(accept: String?, contentType: String?) -> HTTPClientResponse {
    var response = HTTPResponse(status: .ok)
    response.headerFields[.contentType] = contentType
    return HTTPClientResponse(request: request(accept: accept), response: response, responseData: Data())
  }

  @Test("Content-Type is parsed as one media type")
  func responseContentType() {
    let response = HTTPResponse(status: .ok, headerFields: [.contentType: #"text/plain; a="x,y""#])
    #expect(response.contentType == HTTPContentType(#"text/plain; a="x,y""# as String))
    #expect(response.contentTypes?.count == 1)
    #expect(HTTPResponse(status: .ok, headerFields: [.contentType: "not valid"]).contentType == nil)
    #expect(HTTPResponse(status: .ok).contentTypes == nil)
  }

  @Test("Accept ranges drop q, leave out q=0 and invalid entries, and keep quoted commas together")
  func acceptRanges() {
    let accept = #"application/json;q=0.9, text/html;level="1,2", image/png;q=0, bad entry, text/plain;q=2, */*;q=0.1"#
    #expect(request(accept: accept).acceptContentTypes == ["application/json", "text/html", "*/*"])
    #expect(request(accept: nil).acceptContentTypes == nil)
    #expect(request(accept: " ").acceptContentTypes == nil)
    #expect(request(accept: "application/json;q=0").acceptContentTypes == [])
  }

  @Test("Responses in an accepted range pass validation", arguments: [
    ("application/json", "application/json; charset=utf-8"),
    ("application/json", "Application/JSON"),
    ("application/json;q=0.9", "application/json"),
    ("application/xml, */*;q=0.1", "text/html"),
    ("text/*", "text/html; charset=utf-8"),
    ("*/*", nil),
    (nil, nil),
  ] as [(String?, String?)])
  func accepted(accept: String?, contentType: String?) throws {
    try response(accept: accept, contentType: contentType).validate()
  }

  @Test("Responses outside every accepted range fail validation", arguments: [
    ("application/json", "text/html"),
    ("text/*", "application/json"),
    ("application/json;q=0", "application/json"),
    ("application/json", "not a type"),
    ("application/json", "application/json, text/html")
  ])
  func rejected(accept: String, contentType: String) {
    expectHTTPError(isInvalidContentType) {
      try response(accept: accept, contentType: contentType).validate()
    }
  }

  @Test("A missing Content-Type fails validation unless anything is accepted")
  func missingContentType() {
    expectHTTPError(isContentTypeHeaderMissing) {
      try response(accept: "application/json", contentType: nil).validate()
    }
    expectHTTPError(isContentTypeHeaderMissing) {
      try response(accept: "application/json", contentType: " ").validate()
    }
  }

  @Test("String ranges that are not valid accept nothing")
  func invalidStringRanges() throws {
    let response = response(accept: nil, contentType: "application/json")
    try response.validateContentTypes(["application/json"])
    expectHTTPError(isInvalidContentType) {
      try response.validateContentTypes(["not valid"])
    }
  }
}
