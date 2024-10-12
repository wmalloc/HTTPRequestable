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
private let logger = Logger(.init(category: "HTTPTransferable"))
#else
private let logger = Logger(.disabled)
#endif

public protocol HTTPTransferable: Sendable {
  var session: URLSession { get }
  init(session: URLSession)

  var requestInterceptors: [any RequestInterceptor] { get set }
  var responseInterceptors: [any ResponseInterceptor] { get set }

  /// Request data from server
  /// - Parameters:
  ///   - request:  Request where to get the data from
  ///   - delegate: Delegate to handle the request
  /// - Returns: Data, and HTTPResponse
  func data(for request: HTTPRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (Data, HTTPResponse)

  /// Request data from server
  /// - Parameters:
  ///   - request:  Request where to get the data from
  ///   - delegate: Delegate to handle the request
  /// - Returns: Data, and HTTPURLResponse
  func data(for request: URLRequest, delegate: (any URLSessionTaskDelegate)?) async throws -> (Data, HTTPURLResponse)

  /**
   Make a request call and return decoded data as decoded by the transformer, this requesst must return data

   - Parameters:
     - request:    Request where to get the data from
     - transform:  Transformer how to convert the data to different type
     - delegate:   Delegate to handle the request
   - returns: Transformed Object
   */
  func object<ObjectType>(for request: HTTPRequest, transformer: @escaping Transformer<Data, ObjectType>, delegate: (any URLSessionTaskDelegate)?) async throws -> ObjectType

  /**
   Make a request call and return decoded data as decoded by the transformer, this requesst must return data

   - Parameters:
     - request:    Request where to get the data from
     - transform:  Transformer how to convert the data to different type
     - delegate:   Delegate to handle the request
   - returns: Transformed Object
   */
  func object<ObjectType>(for request: URLRequest, transformer: @escaping Transformer<Data, ObjectType>, delegate: (any URLSessionTaskDelegate)?) async throws -> ObjectType

  /**
   Make a request call and return decoded data as decoded by the transformer, this requesst must return data

   - Parameters:
     - route:    Request where to get the data from
     - delegate: Delegate to handle the request
   - returns: Transformed Object
   */
  func object<Route: HTTPRequestable>(for route: Route, delegate: (any URLSessionTaskDelegate)?) async throws -> Route.ResultType
}

public extension HTTPTransferable {
  func data(for request: HTTPRequest, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> (Data, HTTPResponse) {
    logger.trace("[IN]: \(#function)")
    var updateRequest = request
    for interceptor in requestInterceptors {
      try await interceptor.intercept(&updateRequest, for: session)
    }
    let (data, response) = try await session.data(for: updateRequest, delegate: delegate)
    for interceptor in responseInterceptors {
      try await interceptor.intercept(request: request, data: data, response: response)
    }
    switch response.status.kind {
    case .successful:
      return (data, response)
    default:
      throw URLError(URLError.Code(rawValue: response.status.code))
    }
  }

  func data(for request: URLRequest, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> (Data, HTTPURLResponse) {
    logger.trace("[IN]: \(#function)")
    var updateRequest = request
    for interceptor in self.requestInterceptors {
      try await interceptor.intercept(&updateRequest, for: session)
    }
    
    let (rawData, response) = try await session.data(for: updateRequest, delegate: delegate)
    let (data, httpURLResponse) = try (rawData, response.httpURLResponse)
    for interceptor in responseInterceptors {
      try await interceptor.intercept(request: request, data: data, response: httpURLResponse)
    }
    switch httpURLResponse.status.kind {
    case .successful:
      return (data, httpURLResponse)
    default:
      throw URLError(URLError.Code(rawValue: httpURLResponse.status.code))
    }
  }

  func object<ObjectType>(for request: HTTPRequest, transformer: @escaping Transformer<Data, ObjectType>, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> ObjectType {
    logger.trace("[IN]: \(#function)")
    let response = try await data(for: request, delegate: delegate)
    guard let url = request.url else {
      throw URLError(.badURL)
    }
    let httpURLResponse = HTTPURLResponse(httpResponse: response.1, url: url)
    return try transformer(response.0, httpURLResponse)
  }

  func object<ObjectType>(for request: URLRequest, transformer: @escaping Transformer<Data, ObjectType>, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> ObjectType {
    logger.trace("[IN]: \(#function)")
    let (rawData, httpURLResponse) = try await data(for: request, delegate: delegate)
    return try transformer(rawData, httpURLResponse)
  }

  func object<Route: HTTPRequestable>(for route: Route, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> Route.ResultType {
    try await route.httpBody == nil ?
    object(for: route.httpRequest, transformer: route.responseTransformer, delegate: delegate) :
    object(for: route.urlRequest, transformer: route.responseTransformer, delegate: delegate)
  }
}
