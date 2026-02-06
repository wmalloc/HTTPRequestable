//
//  HTTPHeadersTests.swift
//
//
//  Created by Waqar Malik on 1/15/23
//

import Foundation
@testable import HTTPRequestable
import HTTPTypes
import Testing

@Suite("HTTPHeadersTests") struct HTTPHeadersTests {
  static var baseURLString: String {
    "https://api.github.com"
  }

  static var baseURL: URL {
    URL(string: baseURLString)!
  }

  @Test("BaseHeaders")
  func baseHeaders() {
    var headers = HTTPFields()
    headers.append(.defaultUserAgent)

    #expect(!headers.isEmpty)
    #expect(headers.count == 1)
    #expect(headers.contains(.defaultUserAgent))
    #expect(!headers.contains(.contentType(.json)))
  }

  @Test("URLSessionConfiguration")
  func uRLSessionConfiguration() {
    let session = URLSessionConfiguration.default
    session.httpFields = HTTPFields.defaultHeaders
    #expect(session.httpAdditionalHeaders?.count == 3)

    let headers = session.httpFields
    #expect(headers.count == 3)
  }

  @Test("HeaderFieldsCounts")
  func headerFieldsCounts() {
    var fields = HTTPFields.defaultHeaders
    fields.append(HTTPField.accept(.json))
    #expect(fields.count == 4)
    #expect(fields[0].name == .acceptEncoding)
    #expect(fields[1].name == .acceptLanguage)
    #expect(fields[2].name == .userAgent)
    #expect(fields[3].name == .accept)
    fields[.accept] = HTTPContentType.xml.rawValue
    #expect(fields.count == 4)
  }

  @Test("URLRequestHTTPFields")
  func uRLRequestHTTPFields() throws {
    var request = try URLRequest(url: #require(URL(string: "https://api.github.com")))
      .setMethod(.get)
    #expect(request.allHTTPHeaderFields != nil)
    #expect(request.allHTTPHeaderFields?.count == 0)
    request = request.setUserAgent(String.url_userAgent)
    #expect(request.allHTTPHeaderFields?.count == 1)

    request = request.setHttpHeaderFields(HTTPFields.defaultHeaders)
    #expect(request.allHTTPHeaderFields?.count == 3)
  }

  @Test("HTTPFieldsRewValues")
  func hTTPFieldsRewValues() {
    let fields = HTTPFields.defaultHeaders
    let rawValue = fields.rawValue
    #expect(rawValue.count == 3)

    let newFields = HTTPFields(rawValue: rawValue)
    #expect(newFields.count == 3)
  }

  @Test("URLRequestHeaders")
  func uRLRequestHeaders() throws {
    let request = try URLRequest(url: #require(URL(string: "https://api.github.com")))
      .setMethod(.get)
      .setUserAgent(String.url_userAgent)
      .setHttpHeaderFields(HTTPFields.defaultHeaders)
      .addHeader(HTTPField.accept(.json))

    let headers = request.headerFields
    #expect(headers != nil)
    #expect(headers?.count == 4)
    #expect(headers?.contains(.contentType(.xml)) == false)
  }

  @Test("Dictionary")
  func testDictionary() {
    var headers = HTTPFields()
    headers[.contentType] = HTTPContentType.xml.rawValue
    #expect(headers.count == 1)
    #expect(headers[.contentType] == HTTPContentType.xml.rawValue)
    headers[.contentType] = HTTPContentType.json.rawValue
    #expect(headers.count == 1)
    #expect(headers[.contentType] == HTTPContentType.json.rawValue)
    headers.append(HTTPField(name: .authorization, value: "Password"))
    headers.append(HTTPField(name: .contentLength, value: "\(0)"))
    headers[.authorization] = "Token"
    #expect(headers.count == 3)
    let dictionary = headers.rawValue
    #expect(dictionary.count == 3)
  }

  @Test("DefaultRequest")
  func defaultRequest() {
    let request = URLRequest(url: Self.baseURL)
    #expect(request.url?.absoluteString == Self.baseURLString)
    let contentType = request[.contentType]
    #expect(contentType == nil)
    let cacheControl = request[.cacheControl]
    #expect(cacheControl == nil)
    #expect(request.allHTTPHeaderFields == nil)
    #expect(request.httpBody == nil)
    #expect(request.httpShouldHandleCookies)
    #expect(request.cachePolicy == NSURLRequest.CachePolicy.useProtocolCachePolicy)
    #expect(request.timeoutInterval == 60.0)

    #expect(request.contentType == nil)
    #expect(request.userAgent == nil)
    #expect(request == URLRequest(url: Self.baseURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 20.0))
  }

  @Test("DefaultRequestConfigurations")
  func defaultRequestConfigurations() {
    var request = URLRequest(url: Self.baseURL)
      .setCachePolicy(.reloadIgnoringLocalCacheData)
    #expect(request.cachePolicy == NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData)
    request = request
      .setContentType(.json)
    let first = request[.contentType]
    #expect(first == HTTPContentType.json.rawValue)
    #expect(request.allHTTPHeaderFields?.count == 1)
  }

  @Test("QueryItems")
  func testQueryItems() throws {
    var components = try #require(URLComponents(string: Self.baseURLString))
    components = components.setQueryItems([URLQueryItem(name: "test1", value: "test1"), URLQueryItem(name: "test2", value: "test2")])
    #expect(components.queryItems != nil)
    #expect((components.queryItems?.count ?? 0) == 2)
    #expect(components.url?.absoluteString == "\(Self.baseURLString)?test1=test1&test2=test2")
    components = components.appendQueryItems([URLQueryItem(name: "test3", value: "test3")])
    #expect((components.queryItems?.count ?? 0) == 3)
    #expect(components.url?.absoluteString == "\(Self.baseURLString)?test1=test1&test2=test2&test3=test3")
    components = components.setQueryItems([])
    #expect((components.queryItems?.count ?? 0) == 0)
    let absoluteString = components.url?.absoluteString
    #expect(absoluteString != nil)
    #expect(absoluteString == Self.baseURLString)
    components = components.setQueryItems([URLQueryItem(name: "test 3", value: "test 3")])
    #expect((components.queryItems?.count ?? 0) == 1)
    #expect(components.url?.absoluteString == "\(Self.baseURLString)?test%203=test%203")
  }
}
