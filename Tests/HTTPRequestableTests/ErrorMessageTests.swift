//
//  ErrorMessageTests.swift
//
//  Created by Waqar Malik on 11/26/26.
//

import Foundation
@testable import HTTPRequestable
import Testing

struct ErrorMessageTests {
  @Test("HTTPError descriptions", arguments: [
    (HTTPError.invalidURL, "Cannot create URL."),
    (.cannotCreateURLRequest, "Cannot create URLRequest."),
    (.cannotConvertToHTTPResponse, "Cannot convert URLResponse to HTTPResponse."),
    (.cannotConvertToHTTPURLResponse, "Cannot convert URLResponse to HTTPURLResponse."),
    (.contentTypeHeaderMissing, "ContentType header is missing."),
    (.invalidContentType, "ContentType header value is invalid"),
    (.headerValueMissing("mockIdentifier"), "Header missing value: mockIdentifier"),
    (.unacceptableStatusCode(.notFound), "Unacceptable HTTP status code: 404")
  ])
  func httpErrors(error: HTTPError, description: String) {
    #expect(error.description == description)
    #expect(error.errorDescription == description)
  }

  @Test("MultipartFormError descriptions start with their message")
  func multipartErrors() {
    let url = URL(fileURLWithPath: "/tmp/missing.txt")
    #expect(MultipartFormError.badURL(url).errorDescription == "Bad URL file:///tmp/missing.txt")
    #expect(MultipartFormError.accessDenied(url).errorDescription == "Access Denied file:///tmp/missing.txt")
    #expect(MultipartFormError.inputStreamLength("x").errorDescription == "Input stream length x")
  }

  @Test("The body part length message names both lengths")
  func lengthMessage() {
    #expect(MultipartFormBodyPart.lengthMessage(expected: 5, actual: 0) == "Expected body content length 5, encodedLength 0")
  }
}
