//
//  HTTPRequestable.swift
//
//
//  Created by Waqar Malik on 10/17/23.
//

import Foundation
import HTTPTypes
import HTTPTypesFoundation

public typealias HTTPMethod = HTTPRequest.Method
public typealias Transformer<InputType, OutputType> = (InputType, HTTPResponse) throws -> OutputType

public protocol HTTPRequestable {
	associatedtype ResultType

	var scheme: String { get }
	var authority: String { get }
	var method: HTTPMethod { get }
	var path: String { get }
	var queryItems: [URLQueryItem]? { get }
	var headers: HTTPFields { get }
	var transformer: Transformer<Data, ResultType> { get }

	func url(queryItems: [URLQueryItem]?) throws -> URL
	func httpRequest(headers: HTTPFields?, queryItems: [URLQueryItem]?) throws -> HTTPRequest
}

public extension HTTPRequestable {
	var scheme: String {
		"https"
	}

	var method: HTTPMethod {
		.get
	}

	var path: String {
		""
	}

	var queryItems: [URLQueryItem]? {
		nil
	}

	var headers: HTTPFields {
		HTTPFields([.accept(.json), .defaultUserAgent, .defaultAcceptEncoding, .defaultAcceptLanguage])
	}

	func url(queryItems: [URLQueryItem]? = nil) throws -> URL {
		var components = URLComponents()
		components.scheme = scheme
		components.host = authority
		components.path = path
		var items: [URLQueryItem] = self.queryItems ?? []
		items.append(contentsOf: queryItems ?? [])
		components.queryItems = items.isEmpty ? nil : Array(items)
		guard let url = components.url else {
			throw URLError(.badURL)
		}
		return url
	}

	func httpRequest(headers: HTTPFields? = nil, queryItems: [URLQueryItem]? = nil) throws -> HTTPRequest {
		var allHeaders = self.headers
		allHeaders.append(contentsOf: headers ?? [:])
		let request = try HTTPRequest(method: method, url: url(queryItems: queryItems), headerFields: allHeaders)
		return request
	}
}
