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

  /// Request Modifiers
  var requestInterceptors: [any HTTPRequestInterceptor] { get set }

  /// Response Interceptors
  var responseInterceptors: [any HTTPResponseInterceptor] { get set }

  /// Request data from server
  /// - Parameters:
  ///   - request:  Request where to get the data from
  ///   - delegate: Delegate to handle the request
  /// - Returns: Data, and HTTPResponse
  func data(for request: any HTTPRequestable, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPAnyResponse<Data>

  /// Convenience method to upload data using an `HTTPRequestable`; creates and resumes a `URLSessionUploadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to upload data.
  ///   - fileURL: File to upload.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Data and response.
  func upload<Request: HTTPRequestable>(for request: Request, fromFile fileURL: URL, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPAnyResponse<Request.ResultType>

  /// Convenience method to upload data using an `HTTPRequestable`, creates and resumes a `URLSessionUploadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to upload data.
  ///   - bodyData: Data to upload.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Data and response.
  func upload<Request: HTTPRequestable>(for request: Request, from bodyData: Data, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPAnyResponse<Request.ResultType>

  /// Convenience method to download using an `HTTPRequestable`; creates and resumes a `URLSessionDownloadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to download.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Downloaded file URL and response. The file will not be removed automatically.
  func download<Request: HTTPRequestable>(for request: Request, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPAnyResponse<URL>

  /// Returns a byte stream that conforms to AsyncSequence protocol.
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to load data.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Data stream and response.
  func bytes<Request: HTTPRequestable>(for request: Request, delegate: (any URLSessionTaskDelegate)?) async throws -> (URLSession.AsyncBytes, HTTPResponse)

  /**
   Make a request call and return decoded data as decoded by the transformer, this requesst must return data

   - Parameters:
     - route:    Request where to get the data from
     - delegate: Delegate to handle the request
   - returns: Transformed Object
   */
  func object<Request: HTTPRequestable>(for request: Request, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPAnyResponse<Request.ResultType>

  /**
   Make a request call and return decoded data as decoded by the transformer, this requesst must return data

   - Parameters:
   - route:    Request where to get the data from
   - delegate: Delegate to handle the request
   - returns: Transformed Object
   */
  func decoded<Request: HTTPRequestable>(for request: Request, delegate: (any URLSessionTaskDelegate)?) async throws -> Request.ResultType
}

public extension HTTPTransferable {
  func data(for request: any HTTPRequestable, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPAnyResponse<Data> {
    logger.trace("[IN]: \(#function)")
    var updateRequest = try request.httpRequest
    for interceptor in requestInterceptors {
      try await interceptor.intercept(&updateRequest, for: session)
    }
    let result: (Data, HTTPResponse) = if let httpBody = request.httpBody {
      try await session.upload(for: updateRequest, from: httpBody, delegate: delegate)
    } else {
      try await session.data(for: updateRequest, delegate: delegate)
    }
    for interceptor in responseInterceptors {
      try await interceptor.intercept(request: updateRequest, data: result.0, url: nil, response: result.1)
    }
    return try HTTPAnyResponse(request: updateRequest, response: result.1, data: result.0, result: .success(result.0)).validateStatus()
  }

  /// Convenience method to upload data using an `HTTPRequestable`; creates and resumes a `URLSessionUploadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to upload data.
  ///   - fileURL: File to upload.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Data and response.
  func upload<Request: HTTPRequestable>(for request: Request, fromFile fileURL: URL, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPAnyResponse<Request.ResultType> {
    logger.trace("[IN]: \(#function)")
    var updateRequest = try request.httpRequest
    for interceptor in requestInterceptors {
      try await interceptor.intercept(&updateRequest, for: session)
    }
    let (data, response) = try await session.upload(for: updateRequest, fromFile: fileURL, delegate: delegate)
    for interceptor in responseInterceptors {
      try await interceptor.intercept(request: updateRequest, data: data, url: nil, response: response)
    }
    
    let result: HTTPAnyResponse<Request.ResultType> =
    if let error = response.error {
      HTTPAnyResponse(request: updateRequest, response: response, data: data, result: .failure(error))
    } else if let decoded = try request.responseDataTransformer?(data) {
      try HTTPAnyResponse(request: updateRequest, response: response, data: data, result: .success(decoded)).validateStatus()
    } else {
      HTTPAnyResponse(request: updateRequest, response: response, data: data, result: .failure(URLError(.cannotDecodeContentData)))
    }
    return result
  }

  /// Convenience method to upload data using an `HTTPRequestable`, creates and resumes a `URLSessionUploadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to upload data.
  ///   - bodyData: Data to upload.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Data and response.
  func upload<Request: HTTPRequestable>(for request: Request, from bodyData: Data, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPAnyResponse<Request.ResultType> {
    logger.trace("[IN]: \(#function)")
    var updateRequest = try request.httpRequest
    for interceptor in requestInterceptors {
      try await interceptor.intercept(&updateRequest, for: session)
    }
    let (data, response) = try await session.upload(for: updateRequest, from: bodyData, delegate: delegate)
    for interceptor in responseInterceptors {
      try await interceptor.intercept(request: updateRequest, data: data, url: nil, response: response)
    }
    
    let result: HTTPAnyResponse<Request.ResultType> =
    if let error = response.error {
      HTTPAnyResponse(request: updateRequest, response: response, data: data, result: .failure(error))
    } else if let decoded = try request.responseDataTransformer?(data) {
      try HTTPAnyResponse(request: updateRequest, response: response, data: data, result: .success(decoded)).validateStatus()
    } else {
      HTTPAnyResponse(request: updateRequest, response: response, data: data, result: .failure(URLError(.cannotDecodeContentData)))
    }
    return result
  }

  /// Convenience method to download using an `HTTPRequestable`; creates and resumes a `URLSessionDownloadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to download.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Downloaded file URL and response. The file will not be removed automatically.
  func download(for request: some HTTPRequestable, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPAnyResponse<URL> {
    logger.trace("[IN]: \(#function)")
    var updateRequest = try request.httpRequest
    for interceptor in requestInterceptors {
      try await interceptor.intercept(&updateRequest, for: session)
    }
    let (url, response) = try await session.download(for: updateRequest, delegate: delegate)
    for interceptor in responseInterceptors {
      try await interceptor.intercept(request: updateRequest, data: nil, url: url, response: response)
    }
    let result: HTTPAnyResponse<URL> =
    if let error = response.error {
      HTTPAnyResponse(request: updateRequest, response: response, fileURL: url, result: .failure(error))
    } else {
      try HTTPAnyResponse(request: updateRequest, response: response, fileURL: url, result: .success(url)).validateStatus()
    }
    return result
  }

  /// Returns a byte stream that conforms to AsyncSequence protocol.
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to load data.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Data stream and response.
  func bytes(for request: some HTTPRequestable, delegate: (any URLSessionTaskDelegate)?) async throws -> (URLSession.AsyncBytes, HTTPResponse) {
    logger.trace("[IN]: \(#function)")
    var updateRequest = try request.httpRequest
    for interceptor in requestInterceptors {
      try await interceptor.intercept(&updateRequest, for: session)
    }
    return try await session.bytes(for: updateRequest, delegate: delegate)
  }

  /**
   Make a request call and return decoded data as decoded by the transformer, this requesst must return data

   - Parameters:
   - route:    Request where to get the data from
   - delegate: Delegate to handle the request
   - returns: Transformed Object
   */
  func object<Request: HTTPRequestable>(for request: Request, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPAnyResponse<Request.ResultType> {
    let response = try await data(for: request, delegate: delegate)
    let result: HTTPAnyResponse<Request.ResultType> =
    if let error = response.error {
      HTTPAnyResponse(request: response.request, response: response.response, data: response.data, result: .failure(error))
    } else if let data = response.data, let decoded = try request.responseDataTransformer?(data) {
      HTTPAnyResponse(request: response.request, response: response.response, data: response.data, result: .success(decoded))
    } else {
      HTTPAnyResponse(request: response.request, response: response.response, data: response.data, result: .failure(URLError(.cannotDecodeContentData)))
    }
    return result
  }

  /**
   Make a request call and return decoded data as decoded by the transformer, this requesst must return data

   - Parameters:
   - route:    Request where to get the data from
   - delegate: Delegate to handle the request
   - returns: Transformed Object
   */
  func decoded<Request: HTTPRequestable>(for request: Request, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> Request.ResultType {
    let response = try await object(for: request, delegate: delegate)
    if let value = response.value {
      return value
    }

    let error = response.error ?? URLError(.cannotDecodeContentData)
    throw error
  }
}
