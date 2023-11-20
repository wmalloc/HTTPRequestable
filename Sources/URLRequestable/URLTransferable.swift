//
//  URLTransferable.swift
//
//  Created by Waqar Malik on 4/28/23.
//

import Combine
import Foundation

public protocol URLTransferable {
	var session: URLSession { get }

	init(session: URLSession)

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
}

public extension URLTransferable {
	@discardableResult
	func dataTask<T>(for request: URLRequest, transformer: @escaping Transformer<Data, T>, completion: DataHandler<T>?) -> URLSessionDataTask? {
		let dataTask = session.dataTask(with: request) { data, urlResponse, error in
			if let error {
				completion?(.failure(error))
				return
			}

			guard let data, let urlResponse else {
				completion?(.failure(URLError(.badServerResponse)))
				return
			}
			do {
				try urlResponse.url_validate()
				let mapped = try transformer(data)
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
				try result.response.url_validate()
				try result.data.url_validateNotEmptyData()
				return try transformer(result.data)
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
