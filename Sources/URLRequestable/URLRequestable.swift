//
//  URLRequestable.swift
//
//  Created by Waqar Malik on 4/27/23.
//

import Foundation
import HTTPTypes

public protocol URLRequestable: HTTPRequestable {
	var apiBaseURLString: String { get }
	var body: Data? { get }

	func urlRequest(headers: HTTPFields?, queryItems: [URLQueryItem]?) throws -> URLRequest
}

public extension URLRequestable {
	var apiBaseURLString: String {
		scheme + "://" + authority + path
	}

	var body: Data? {
		nil
	}

	func url(queryItems: [URLQueryItem]? = nil) throws -> URL {
		guard var components = URLComponents(string: apiBaseURLString) else {
			throw URLError(.badURL)
		}
		var items = self.queryItems ?? []
		items.append(contentsOf: queryItems ?? [])
		components = components
			.appendQueryItems(items)
			.setPath(path)
		guard let url = components.url else {
			throw URLError(.unsupportedURL)
		}
		return url
	}

	func urlRequest(headers: HTTPFields? = nil, queryItems: [URLQueryItem]? = nil) throws -> URLRequest {
		let url = try url(queryItems: queryItems)
		let request = URLRequest(url: url)
			.setMethod(method)
			.addHeaderFields(self.headers)
			.addHeaderFields(headers)
			.setHttpBody(body, contentType: .json)
		return request
	}
}
