//
//  URLRequestable.swift
//
//  Created by Waqar Malik on 4/27/23.
//

import Foundation
import HTTPTypes

public typealias URLDataResponse = (data: Data, response: URLResponse)
public typealias Transformer<InputType, OutputType> = (InputType) throws -> OutputType

public protocol URLRequestable: HTTPRequstable {
	var apiBaseURLString: String { get }
	var body: Data? { get }

	func urlRequest(headers: HTTPFields?, queryItems: Set<URLQueryItem>?) throws -> URLRequest
}

public extension URLRequestable {
	var apiBaseURLString: String {
		scheme + "://" + authority + path
	}

	var body: Data? {
		nil
	}

	func url(queryItems: Set<URLQueryItem>? = nil) throws -> URL {
		guard var components = URLComponents(string: apiBaseURLString) else {
			throw URLError(.badURL)
		}
		var items = self.queryItems ?? []
		items.formUnion(queryItems ?? [])
		components = components
			.appendQueryItems(Array(items))
			.setPath(path)
		guard let url = components.url else {
			throw URLError(.unsupportedURL)
		}
		return url
	}

	func urlRequest(headers: HTTPFields? = nil, queryItems: Set<URLQueryItem>? = nil) throws -> URLRequest {
		let url = try url(queryItems: queryItems)
		let request = URLRequest(url: url)
			.setMethod(method)
			.addHeaderFields(self.headers)
			.addHeaderFields(headers)
			.setHttpBody(body, contentType: .json)
		return request
	}
}
