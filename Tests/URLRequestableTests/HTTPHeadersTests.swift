//
//  HTTPHeadersTests.swift
//
//
//  Created by Waqar Malik on 1/15/23.
//  Copyright © 2020 Waqar Malik All rights reserved.
//

import HTTPTypes
@testable import URLRequestable
import XCTest
import HTTPTypes

final class HTTPHeadersTests: XCTestCase {
	static let baseURLString = "http://localhost:8080"
	static let baseURL = URL(string: "http://localhost:8080")!

	func testBaseHeaders() throws {
		let headers = HTTPHeaders()
			.add(.defaultAcceptLanguage)
			.add(.defaultAcceptEncoding)
			.add(.defaultUserAgent)

		XCTAssertFalse(headers.isEmpty)
		XCTAssertEqual(headers.count, 3)
		XCTAssertTrue(headers.contains(.defaultUserAgent))
		XCTAssertFalse(headers.contains(.contentType(.json)))
	}

	func testURLSessionConfiguration() throws {
		let session = URLSessionConfiguration.default
		session.headers = HTTPHeaders.defaultHeaders
		XCTAssertEqual(session.httpAdditionalHeaders?.count, 3)

		let headers = session.headers
		XCTAssertEqual(headers?.count, 3)
	}

	func testURLRequestHeaders() throws {
		let request = URLRequest(url: URL(string: "https://api.github.com")!)
			.setMethod(.get)
			.setUserAgent(String.url_userAgent)
			.setHttpHeaders(HTTPHeaders.defaultHeaders)
			.addHeader(HTTPField.accept(.json))

		let headers = request.headers
		XCTAssertNotNil(headers)
		XCTAssertEqual(headers?.count, 4)
		XCTAssertFalse(headers!.contains(.contentType(.xml)))
		XCTAssertTrue(headers!.contains(.defaultAcceptLanguage))
	}

	func testDictionary() throws {
		var headers = HTTPHeaders()
		headers[.contentType] = .xml
		XCTAssertEqual(headers.count, 1)
		XCTAssertEqual(headers[.contentType], .xml)
		headers[.contentType] = .json
		XCTAssertEqual(headers.count, 1)
		XCTAssertEqual(headers[.contentType], .json)
		headers = headers.add(HTTPField(name: .authorization, value: "Password"))
			.add(HTTPField(name: .contentLength, value: "\(0)"))
			.add(.authorization(token: "Token"))
		XCTAssertEqual(headers.count, 3)
		let dictionary = headers.dictionary
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
		XCTAssertEqual(first, .json)
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
