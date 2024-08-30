//
//  HTTPTransferable.swift
//
//
//  Created by Waqar Malik on 11/17/23
//

import Combine
import Foundation
import HTTPTypes
import HTTPTypesFoundation
import OSLog

#if DEBUG
private let logger: OSLog = .init(subsystem: "com.waqarmalik.HTTPRequestable", category: "HTTPTransferable")
#else
private let logger: OSLog = .disabled
#endif

public typealias DataHandler<T> = @Sendable (Result<T, any Error>) -> Void

public protocol HTTPTransferable: Sendable {
  var session: URLSession { get }

  init(session: URLSession)

  var requestInterceptors: [any RequestInterceptor] { get set }
  var responseInterceptors: [any ResponseInterceptor] { get set }

  /**
   Make a request call and return decoded data as decoded by the transformer, this requesst must return data

   - parameter request:    Request where to get the data from
   - parameter transform:  Transformer how to convert the data to different type
   - parameter delegate:   Delegate to handle the request

   - returns: Transformed Object
   */
  func object<ObjectType>(for request: HTTPRequest, transformer: @escaping Transformer<Data, ObjectType>, delegate: (any URLSessionTaskDelegate)?) async throws -> ObjectType

  /**
   Make a request call and return decoded data as decoded by the transformer, this requesst must return data

   - parameter request:    Request where to get the data from
   - parameter transform:  Transformer how to convert the data to different type
   - parameter delegate:   Delegate to handle the request

   - returns: Transformed Object
   */
  func object<ObjectType>(for request: URLRequest, transformer: @escaping Transformer<Data, ObjectType>, delegate: (any URLSessionTaskDelegate)?) async throws -> ObjectType

  /**
   Make a request call and return decoded data as decoded by the transformer, this requesst must return data

   - parameter route:    Request where to get the data from
   - parameter delegate:   Delegate to handle the request

   - returns: Transformed Object
   */
  func object<Route: HTTPRequestable>(for route: Route, delegate: (any URLSessionTaskDelegate)?) async throws -> Route.ResultType

  /**
   Make a request call and return decoded data as decoded by the transformer, this requesst must return data

   - parameter request:    Request where to get the data from
   - parameter transform:  Transformer how to convert the data to different type
   - parameter completion: completion handler

   - returns: URLSessionDataTask
   */
  func dataTask<ObjectType>(for request: URLRequest, transformer: @escaping Transformer<Data, ObjectType>, completion: DataHandler<ObjectType>?) -> URLSessionDataTask?

  /**
   Make a request call and return decoded data as decoded by the transformer, this requesst must return data

   - parameter route:    Route to create URLRequest
   - parameter completion: completion handler

   - returns: URLSessionDataTask
   */
  func dataTask<Route: HTTPRequestable>(for route: Route, completion: DataHandler<Route.ResultType>?) -> URLSessionDataTask?

  /**
   Make a request call and return decoded data as decoded by the transformer, this requesst must return data

   - parameter request:    Request where to get the data from
   - parameter transform:  Transformer how to convert the data to different type

   - returns: Publisher with decoded response
   */
  func dataPublisher<ObjectType>(for request: URLRequest, transformer: @escaping Transformer<Data, ObjectType>) -> AnyPublisher<ObjectType, any Error>

  /**
   Make a request call and return decoded data as decoded by the transformer, this requesst must return data

   - parameter route:    Route to create URLRequest
   - parameter transform:  Transformer how to convert the data to different type

   - returns: Publisher with decoded response
   */
  func dataPublisher<Route: HTTPRequestable>(for route: Route) -> AnyPublisher<Route.ResultType, any Error>
}

public extension HTTPTransferable {
  func object<ObjectType>(for request: HTTPRequest, transformer: @escaping Transformer<Data, ObjectType>, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> ObjectType {
    os_log(.debug, log: logger, "[IN]: %@", #function)
    var updateRequest = request
    for interceptor in requestInterceptors {
      updateRequest = try await interceptor.intercept(updateRequest, for: session)
    }
    let (data, response) = try await session.data(for: updateRequest, delegate: delegate)
    for interceptor in responseInterceptors {
      try await interceptor.intercept(data: data, response: response)
    }
    switch response.status.kind {
    case .successful:
      guard let url = request.url else {
        throw URLError(.badURL)
      }
      let httpURLResponse = HTTPURLResponse(httpResponse: response, url: url)
      return try transformer(data, httpURLResponse)

    default:
      throw URLError(URLError.Code(rawValue: response.status.code))
    }
  }

  func object<ObjectType>(for request: URLRequest, transformer: @escaping Transformer<Data, ObjectType>, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> ObjectType {
    os_log(.debug, log: logger, "[IN]: %@", #function)
    var updateRequest = request
    for interceptor in requestInterceptors {
      updateRequest = try await interceptor.intercept(updateRequest, for: session)
    }
    let (rawData, response) = try await session.data(for: request, delegate: delegate)
    let (data, httpURLResponse) = try (rawData, response.httpURLResponse)
    for interceptor in responseInterceptors {
      try await interceptor.intercept(data: data, response: httpURLResponse)
    }
    return try transformer(data, httpURLResponse)
  }

  func object<Route: HTTPRequestable>(for route: Route, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> Route.ResultType {
    try await object(for: route.urlRequest(), transformer: route.responseTransformer, delegate: delegate)
  }
}

public extension HTTPTransferable {
  @discardableResult
  func dataTask<ObjectType>(for request: URLRequest, transformer: @escaping Transformer<Data, ObjectType>, completion: DataHandler<ObjectType>?) -> URLSessionDataTask? {
    os_log(.debug, log: logger, "[IN]: %@", #function)
    let dataTask = session.dataTask(with: request) { data, urlResponse, error in
      if let error {
        completion?(.failure(error))
        return
      }

      guard let data else {
        completion?(.failure(URLError(.fileDoesNotExist)))
        return
      }
      do {
        let httpURLResponse = try urlResponse?.httpURLResponse
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
  func dataTask<Route: HTTPRequestable>(for route: Route, completion: DataHandler<Route.ResultType>?) -> URLSessionDataTask? {
    os_log(.debug, log: logger, "[IN]: %@", #function)
    guard let urlRequest = try? route.urlRequest() else {
      return nil
    }
    return dataTask(for: urlRequest, transformer: route.responseTransformer, completion: completion)
  }
}

public extension HTTPTransferable {
  func dataPublisher<ObjectType>(for request: URLRequest, transformer: @escaping Transformer<Data, ObjectType>) -> AnyPublisher<ObjectType, any Error> {
    os_log(.debug, log: logger, "[IN]: %@", #function)
    return session.dataTaskPublisher(for: request)
      .tryMap { result -> URLSession.DataTaskPublisher.Output in
        let httpURLResponse = try result.response.httpURLResponse
        return (result.data, httpURLResponse)
      }
      .tryMap { result -> ObjectType in
        let httpURLResponse = try result.response.httpURLResponse
        try result.data.url_validateNotEmptyData()
        return try transformer(result.data, httpURLResponse)
      }
      .eraseToAnyPublisher()
  }

  func dataPublisher<Route: HTTPRequestable>(for route: Route) -> AnyPublisher<Route.ResultType, any Error> {
    os_log(.debug, log: logger, "[IN]: %@", #function)
    guard let urlRequest = try? route.urlRequest() else {
      return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
    }

    return dataPublisher(for: urlRequest, transformer: route.responseTransformer)
  }
}
