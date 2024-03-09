//
//  URLTransferable.swift
//
//  Created by Waqar Malik on 4/28/23.
//

import Combine
import Foundation
import HTTPTypes
import HTTPTypesFoundation

public typealias DataHandler<T> = (Result<T, Error>) -> Void

public protocol URLTransferable: HTTPTransferable {
	/**
	 Make a request call and return decoded data as decoded by the transformer, this requesst must return data

	 - parameter request:    Request where to get the data from
	 - parameter transform:  Transformer how to convert the data to different type
	 - parameter completion: completion handler

	 - returns: URLSessionDataTask
	 */
	func dataTask<T>(for request: URLRequest, transformer: @escaping Transformer<Data, T>, completion: DataHandler<T>?) -> URLSessionDataTask?

	/**
	 Make a request call and return decoded data as decoded by the transformer, this requesst must return data

	 - parameter route:    Route to create URLRequest
	 - parameter completion: completion handler

	 - returns: URLSessionDataTask
	 */
	func dataTask<T: URLRequestable>(for route: T, completion: DataHandler<T.ResultType>?) -> URLSessionDataTask?

	/**
	 Make a request call and return decoded data as decoded by the transformer, this requesst must return data

	 - parameter request:    Request where to get the data from
	 - parameter transform:  Transformer how to convert the data to different type

	 - returns: Publisher with decoded response
	 */
	func dataPublisher<ObjectType>(for request: URLRequest, transformer: @escaping Transformer<Data, ObjectType>) -> AnyPublisher<ObjectType, Error>

	/**
	 Make a request call and return decoded data as decoded by the transformer, this requesst must return data

	 - parameter route:    Route to create URLRequest
	 - parameter transform:  Transformer how to convert the data to different type

	 - returns: Publisher with decoded response
	 */
	func dataPublisher<T: URLRequestable>(for route: T) -> AnyPublisher<T.ResultType, Error>

	/**
	 Make a request call and return decoded data as decoded by the transformer, this requesst must return data

	 - parameter request:    Request where to get the data from
	 - parameter transform:  Transformer how to convert the data to different type
	 - parameter delegate:   Delegate to handle the request

	 - returns: Transformed Object
	 */
	func data<ObjectType>(for request: URLRequest, transformer: @escaping Transformer<Data, ObjectType>, delegate: URLSessionTaskDelegate?) async throws -> ObjectType

	/**
	 Make a request call and return decoded data as decoded by the transformer, this requesst must return data

	 - parameter route:    Request where to get the data from
	 - parameter transform:  Transformer how to convert the data to different type
	 - parameter delegate:   Delegate to handle the request

	 - returns: Transformed Object
	 */
	func data<T: URLRequestable>(for route: T, delegate: URLSessionTaskDelegate?) async throws -> T.ResultType
}

public extension URLTransferable {
	@discardableResult
	func dataTask<T>(for request: URLRequest, transformer: @escaping Transformer<Data, T>, completion: DataHandler<T>?) -> URLSessionDataTask? {
		let dataTask = session.dataTask(with: request) { data, urlResponse, error in
			if let error {
				completion?(.failure(error))
				return
			}

			guard let data, let response = (urlResponse as? HTTPURLResponse)?.httpResponse else {
				completion?(.failure(URLError(.badServerResponse)))
				return
			}
			do {
				let mapped = try transformer(data, response)
				completion?(.success(mapped))
			} catch {
				completion?(.failure(error))
			}
		}
		dataTask.resume()
		return dataTask
	}

	@discardableResult
	func dataTask<T: URLRequestable>(for route: T, completion: DataHandler<T.ResultType>?) -> URLSessionDataTask? {
		guard let urlRequest = try? route.urlRequest(headers: nil, queryItems: nil) else {
			return nil
		}
		return dataTask(for: urlRequest, transformer: route.transformer, completion: completion)
	}
}

public extension URLTransferable {
	func dataPublisher<ObjectType>(for request: URLRequest, transformer: @escaping Transformer<Data, ObjectType>) -> AnyPublisher<ObjectType, Error> {
		session.dataTaskPublisher(for: request)
			.tryMap { result -> ObjectType in
				let httpResponse = try result.response.httpResponse
				try result.data.url_validateNotEmptyData()
				return try transformer(result.data, httpResponse)
			}
			.eraseToAnyPublisher()
	}

	func dataPublisher<T: URLRequestable>(for route: T) -> AnyPublisher<T.ResultType, Error> {
		guard let urlRequest = try? route.urlRequest() else {
			return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
		}

		return dataPublisher(for: urlRequest, transformer: route.transformer)
	}
}

public extension URLTransferable {
	func data<ObjectType>(for request: URLRequest, transformer: @escaping Transformer<Data, ObjectType>, delegate: URLSessionTaskDelegate? = nil) async throws -> ObjectType {
		let (data, response) = try await session.data(for: request, delegate: delegate)
		let httpResponse = try response.httpResponse
		try data.url_validateNotEmptyData()
		return try transformer(data, httpResponse)
	}

	func data<T: URLRequestable>(for route: T, delegate: URLSessionTaskDelegate? = nil) async throws -> T.ResultType {
		let request = try route.urlRequest(headers: nil, queryItems: nil)
		return try await data(for: request, transformer: route.transformer, delegate: delegate)
	}
}
