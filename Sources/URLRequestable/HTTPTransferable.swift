//
//  HTTPTransferable.swift
//
//
//  Created by Waqar Malik on 11/17/23.
//

import Combine
import Foundation
import HTTPTypes
import HTTPTypesFoundation

public typealias DataHandler<T> = (Result<T, Error>) -> Void

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
	func object<ObjectType>(for request: HTTPRequest, transformer: @escaping Transformer<Data, ObjectType>, delegate: URLSessionTaskDelegate?) async throws -> ObjectType

  /**
   Make a request call and return decoded data as decoded by the transformer, this requesst must return data
   
   - parameter request:    Request where to get the data from
   - parameter transform:  Transformer how to convert the data to different type
   - parameter delegate:   Delegate to handle the request
   
   - returns: Transformed Object
   */
  func object<ObjectType>(for request: URLRequest, transformer: @escaping Transformer<Data, ObjectType>, delegate: URLSessionTaskDelegate?) async throws -> ObjectType

	/**
	 Make a request call and return decoded data as decoded by the transformer, this requesst must return data

	 - parameter route:    Request where to get the data from
	 - parameter delegate:   Delegate to handle the request

	 - returns: Transformed Object
	 */
	func object<T: HTTPRequestable>(for route: T, delegate: URLSessionTaskDelegate?) async throws -> T.ResultType
  
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
  func dataTask<T: HTTPRequestable>(for route: T, completion: DataHandler<T.ResultType>?) -> URLSessionDataTask?
  
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
  func dataPublisher<T: HTTPRequestable>(for route: T) -> AnyPublisher<T.ResultType, Error>
}

public extension HTTPTransferable {
	func object<ObjectType>(for request: HTTPRequest, transformer: @escaping Transformer<Data, ObjectType>, delegate: URLSessionTaskDelegate? = nil) async throws -> ObjectType {
		let (data, response) = try await session.data(for: request, delegate: delegate)
		switch response.status.kind {
		case .successful:
      guard let url = request.url, let httpURLResponse = HTTPURLResponse(httpResponse: response, url: url) else {
        throw URLError(.badURL)
      }
			return try transformer(data, httpURLResponse)
		default:
			throw URLError(URLError.Code(rawValue: response.status.code))
		}
	}

  func object<ObjectType>(for request: URLRequest, transformer: @escaping Transformer<Data, ObjectType>, delegate: URLSessionTaskDelegate? = nil) async throws -> ObjectType {
    let (data, response) = try await session.data(for: request, delegate: delegate)
    guard let httpURLResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }
    return try transformer(data, httpURLResponse)
  }

	func object<T: HTTPRequestable>(for route: T, delegate: URLSessionTaskDelegate? = nil) async throws -> T.ResultType {
    let request = try route.urlRequest()
		return try await object(for: request, transformer: route.transformer, delegate: delegate)
	}
}

public extension HTTPTransferable {
  @discardableResult
  func dataTask<T>(for request: URLRequest, transformer: @escaping Transformer<Data, T>, completion: DataHandler<T>?) -> URLSessionDataTask? {
    let dataTask = session.dataTask(with: request) { data, urlResponse, error in
      if let error {
        completion?(.failure(error))
        return
      }
      
      guard let data, let httpURLResponse = urlResponse as? HTTPURLResponse else {
        completion?(.failure(URLError(.badServerResponse)))
        return
      }
      do {
        let mapped = try transformer(data, httpURLResponse)
        completion?(.success(mapped))
      } catch {
        completion?(.failure(error))
      }
    }
    dataTask.resume()
    return dataTask
  }
  
  @discardableResult
  func dataTask<T: HTTPRequestable>(for route: T, completion: DataHandler<T.ResultType>?) -> URLSessionDataTask? {
    guard let urlRequest = try? route.urlRequest() else {
      return nil
    }
    return dataTask(for: urlRequest, transformer: route.transformer, completion: completion)
  }
}

public extension HTTPTransferable {
  func dataPublisher<ObjectType>(for request: URLRequest, transformer: @escaping Transformer<Data, ObjectType>) -> AnyPublisher<ObjectType, Error> {
    session.dataTaskPublisher(for: request)
      .tryMap { result -> ObjectType in
        guard let httpURLResponse = result.response as? HTTPURLResponse else {
          throw URLError(.badServerResponse)
        }
        try result.data.url_validateNotEmptyData()
        return try transformer(result.data, httpURLResponse)
      }
      .eraseToAnyPublisher()
  }
  
  func dataPublisher<T: HTTPRequestable>(for route: T) -> AnyPublisher<T.ResultType, Error> {
    guard let urlRequest = try? route.urlRequest() else {
      return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
    }
    
    return dataPublisher(for: urlRequest, transformer: route.transformer)
  }
}
