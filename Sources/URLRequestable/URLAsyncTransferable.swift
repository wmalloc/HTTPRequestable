//
//  URLRequestAsyncTransferable.swift
//
//  Created by Waqar Malik on 7/15/23.
//

import Foundation
import HTTPTypes

@available(macOS 12, iOS 15, tvOS 15, macCatalyst 15, watchOS 8, *)
public protocol URLAsyncTransferable: URLTransferable {
	/**
	 Make a request call and return decoded data as decoded by the transformer, this requesst must return data

	 - parameter request:    Request where to get the data from
	 - parameter transform:  Transformer how to convert the data to different type
   - parameter delegate:   Delegate to handle the request

	 - returns: Transformed Object
	 */
	func data<ObjectType>(for request: URLRequest, transformer: @escaping AsyncTransformer<Data, ObjectType>, delegate: URLSessionTaskDelegate?) async throws -> ObjectType

	/**
	 Make a request call and return decoded data as decoded by the transformer, this requesst must return data

	 - parameter route:    Request where to get the data from
	 - parameter transform:  Transformer how to convert the data to different type
   - parameter delegate:   Delegate to handle the request

	 - returns: Transformed Object
	 */
  func data<T: URLAsyncRequestable>(for route: T, delegate: URLSessionTaskDelegate?) async throws -> T.ResultType
}

@available(macOS 12, iOS 15, tvOS 15, macCatalyst 15, watchOS 8, *)
public extension URLAsyncTransferable {
	func data<ObjectType>(for request: URLRequest, transformer: @escaping AsyncTransformer<Data, ObjectType>, delegate: URLSessionTaskDelegate? = nil) async throws -> ObjectType {
		let result = try await session.data(for: request, delegate: delegate)
    try result.1.url_validate()
    try result.0.url_validateNotEmptyData()
    return try await transformer(result.0)
	}

  func data<T: URLAsyncRequestable>(for route: T, delegate: URLSessionTaskDelegate? = nil) async throws -> T.ResultType {
		let request = try route.urlRequest(headers: nil, queryItems: nil)
    return try await data(for: request, transformer: route.transformer, delegate: delegate)
	}
}
