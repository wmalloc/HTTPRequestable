//
//  HTTPHeadersTests.swift
//
//
//  Created by Waqar Malik on 1/15/23
//

@testable import HTTPRequestable
import HTTPTypes
import XCTest

final class HTTPHeadersTests: XCTestCase {
  private static let baseURLString = "http://localhost:8080"
  private static let baseURL = URL(string: "http://localhost:8080")!

  func testBaseHeaders() throws {
    var headers = HTTPFields()
    headers.append(.defaultUserAgent)

    XCTAssertFalse(headers.isEmpty)
    XCTAssertEqual(headers.count, 1)
    XCTAssertTrue(headers.contains(.defaultUserAgent))
    XCTAssertFalse(headers.contains(.contentType(.json)))
  }

  func testURLSessionConfiguration() throws {
    let session = URLSessionConfiguration.default
    session.httpFields = HTTPFields.defaultHeaders
    XCTAssertEqual(session.httpAdditionalHeaders?.count, 1)

    let headers = session.httpFields
    XCTAssertEqual(headers?.count, 1)
  }

  func testHeaderFieldsCounts() throws {
    var fields = HTTPFields.defaultHeaders
    fields.append(HTTPField.accept(.json))
    XCTAssertEqual(fields.count, 2)
    XCTAssertEqual(fields[0].name, .userAgent)
    XCTAssertEqual(fields[1].name, .accept)
    fields[.accept] = HTTPContentType.xml.rawValue
    XCTAssertEqual(fields.count, 2)
  }

  func testURLRequestHTTPFields() throws {
    var request = URLRequest(url: URL(string: "https://api.github.com")!)
      .setMethod(.get)
    XCTAssertNotNil(request.allHTTPHeaderFields)
    XCTAssertEqual(request.allHTTPHeaderFields?.count, 0)
    request = request.setUserAgent(String.url_userAgent)
    XCTAssertEqual(request.allHTTPHeaderFields?.count, 1)

    request = request.setHttpHeaderFields(HTTPFields.defaultHeaders)
    XCTAssertEqual(request.allHTTPHeaderFields?.count, 1)
  }

  func testHTTPFieldsRewValues() throws {
    let fields = HTTPFields.defaultHeaders
    let rawValue = fields.rawValue
    XCTAssertEqual(rawValue.count, 1)

    let newFields = HTTPFields(rawValue: rawValue)
    XCTAssertEqual(newFields.count, 1)
  }

  func testURLRequestHeaders() throws {
    let request = URLRequest(url: URL(string: "https://api.github.com")!)
      .setMethod(.get)
      .setUserAgent(String.url_userAgent)
      .setHttpHeaderFields(HTTPFields.defaultHeaders)
      .addHeader(HTTPField.accept(.json))

    let headers = request.headerFields
    XCTAssertNotNil(headers)
    XCTAssertEqual(headers?.count, 2)
    XCTAssertFalse(headers!.contains(.contentType(.xml)))
  }

  func testDictionary() throws {
    var headers = HTTPFields()
    headers[.contentType] = HTTPContentType.xml.rawValue
    XCTAssertEqual(headers.count, 1)
    XCTAssertEqual(headers[.contentType], HTTPContentType.xml.rawValue)
    headers[.contentType] = HTTPContentType.json.rawValue
    XCTAssertEqual(headers.count, 1)
    XCTAssertEqual(headers[.contentType], HTTPContentType.json.rawValue)
    headers.append(HTTPField(name: .authorization, value: "Password"))
    headers.append(HTTPField(name: .contentLength, value: "\(0)"))
    headers[.authorization] = "Token"
    XCTAssertEqual(headers.count, 3)
    let dictionary = headers.rawValue
    XCTAssertEqual(dictionary.count, 3)
  }

  func testDefaultRequest() throws {
    let request = URLRequest(url: Self.baseURL)
    XCTAssertEqual(request.url?.absoluteString, Self.baseURLString)
    let contentType = request[.contentType]
    XCTAssertNil(contentType)
    let cacheControl = request[.cacheControl]
    XCTAssertNil(cacheControl)
    XCTAssertNil(request.allHTTPHeaderFields)
    XCTAssertNil(request.httpBody)
    XCTAssertTrue(request.httpShouldHandleCookies)
    XCTAssertEqual(request.cachePolicy, NSURLRequest.CachePolicy.useProtocolCachePolicy)
    XCTAssertEqual(request.timeoutInterval, 60.0)

    XCTAssertNil(request.contentType)
    XCTAssertNil(request.userAgent)
    XCTAssertEqual(request, URLRequest(url: Self.baseURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 20.0))
  }

  func testDefaultRequestConfigurations() throws {
    var request = URLRequest(url: Self.baseURL)
      .setCachePolicy(.reloadIgnoringLocalCacheData)
    XCTAssertEqual(request.cachePolicy, NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData)
    request = request
      .setContentType(.json)
    let first = request[.contentType]
    XCTAssertEqual(first, HTTPContentType.json.rawValue)
    XCTAssertEqual(request.allHTTPHeaderFields?.count, 1)
  }

  func testQueryItems() throws {
    var components = URLComponents(string: Self.baseURLString)!
    components = components.setQueryItems([URLQueryItem(name: "test1", value: "test1"), URLQueryItem(name: "test2", value: "test2")])
    XCTAssertNotNil(components.queryItems)
    XCTAssertEqual(components.queryItems?.count ?? 0, 2)
    XCTAssertEqual(components.url?.absoluteString, "\(Self.baseURLString)?test1=test1&test2=test2")
    components = components.appendQueryItems([URLQueryItem(name: "test3", value: "test3")])
    XCTAssertEqual(components.queryItems?.count ?? 0, 3)
    XCTAssertEqual(components.url?.absoluteString, "\(Self.baseURLString)?test1=test1&test2=test2&test3=test3")
    components = components.setQueryItems([])
    XCTAssertEqual(components.queryItems?.count ?? 0, 0)
    let absoluteString = components.url?.absoluteString
    XCTAssertNotNil(absoluteString)
    XCTAssertEqual(absoluteString!, Self.baseURLString)
    components = components.setQueryItems([URLQueryItem(name: "test 3", value: "test 3")])
    XCTAssertEqual(components.queryItems?.count ?? 0, 1)
    XCTAssertEqual(components.url?.absoluteString, "\(Self.baseURLString)?test%203=test%203")
  }
}
