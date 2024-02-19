//
//  HTTPTransferable.swift
//
//
//  Created by Waqar Malik on 11/17/23.
//

import Foundation
import HTTPTypes
import HTTPTypesFoundation

@available(macOS 12, iOS 15, tvOS 15, macCatalyst 15, watchOS 8, *)
public protocol HTTPTransferable {
	var session: URLSession { get }

	init(session: URLSession)
	/**
	 Make a request call and return decoded data as decoded by the transformer, this requesst must return data

	 - parameter request:    Request where to get the data from
	 - parameter transform:  Transformer how to convert the data to different type
	 - parameter delegate:   Delegate to handle the request

	 - returns: Transformed Object
	 */
	func data<ObjectType>(for request: HTTPRequest, transformer: @escaping Transformer<Data, ObjectType>, delegate: URLSessionTaskDelegate?) async throws -> ObjectType

	/**
	 Make a request call and return decoded data as decoded by the transformer, this requesst must return data

	 - parameter route:    Request where to get the data from
	 - parameter delegate:   Delegate to handle the request

	 - returns: Transformed Object
	 */
	func data<T: HTTPRequestable>(for route: T, delegate: URLSessionTaskDelegate?) async throws -> T.ResultType
}

@available(macOS 12, iOS 15, tvOS 15, macCatalyst 15, watchOS 8, *)
public extension HTTPTransferable {
	func data<ObjectType>(for request: HTTPRequest, transformer: @escaping Transformer<Data, ObjectType>, delegate: URLSessionTaskDelegate? = nil) async throws -> ObjectType {
		let (data, response) = try await session.data(for: request, delegate: delegate)
		switch response.status.kind {
		case .successful:
			return try transformer(data)
		default:
			throw URLError(URLError.Code(rawValue: response.status.code))
		}
	}

	func data<T: HTTPRequestable>(for route: T, delegate: URLSessionTaskDelegate? = nil) async throws -> T.ResultType {
		let request = try route.httpRequest(headers: nil, queryItems: nil)
		return try await data(for: request, transformer: route.transformer, delegate: delegate)
	}
}
