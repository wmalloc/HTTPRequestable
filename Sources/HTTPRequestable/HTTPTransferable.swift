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
  var requestInterceptors: [any RequestInterceptor] { get set }

  /// Response Interceptors
  var responseInterceptors: [any ResponseInterceptor] { get set }

  /// Request data from server
  /// - Parameters:
  ///   - request:  Request where to get the data from
  ///   - delegate: Delegate to handle the request
  /// - Returns: Data, and HTTPResponse
  func data(for request: any HTTPRequestable, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPDataResponse<Data>

  /// Convenience method to upload data using an `HTTPRequestable`; creates and resumes a `URLSessionUploadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to upload data.
  ///   - fileURL: File to upload.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Data and response.
  func upload<Request: HTTPRequestable>(for request: Request, fromFile fileURL: URL, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPDataResponse<Request.ResultType>

  /// Convenience method to upload data using an `HTTPRequestable`, creates and resumes a `URLSessionUploadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to upload data.
  ///   - bodyData: Data to upload.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Data and response.
  func upload<Request: HTTPRequestable>(for request: Request, from bodyData: Data, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPDataResponse<Request.ResultType>

  /// Convenience method to download using an `HTTPRequestable`; creates and resumes a `URLSessionDownloadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to download.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Downloaded file URL and response. The file will not be removed automatically.
  func download<Request: HTTPRequestable>(for request: Request, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPDownloadResponse<URL>

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
  func object<Request: HTTPRequestable>(for request: Request, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPDataResponse<Request.ResultType>
}

public extension HTTPTransferable {
  func data(for request: any HTTPRequestable, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPDataResponse<Data> {
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
    let dataResponse = HTTPDataResponse(request: updateRequest, data: result.0, response: result.1, result: .success(result.0))
    return dataResponse
  }

  /// Convenience method to upload data using an `HTTPRequestable`; creates and resumes a `URLSessionUploadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to upload data.
  ///   - fileURL: File to upload.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Data and response.
  func upload<Request: HTTPRequestable>(for request: Request, fromFile fileURL: URL, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPDataResponse<Request.ResultType> {
    logger.trace("[IN]: \(#function)")
    var updateRequest = try request.httpRequest
    for interceptor in requestInterceptors {
      try await interceptor.intercept(&updateRequest, for: session)
    }
    let (data, response) = try await session.upload(for: updateRequest, fromFile: fileURL, delegate: delegate)
    for interceptor in responseInterceptors {
      try await interceptor.intercept(request: updateRequest, data: data, url: nil, response: response)
    }
    if let error = response.error {
      return HTTPDataResponse(request: updateRequest, data: data, response: response, result: .failure(error))
    }
    guard let decoded = try request.responseDataTransformer?(data) else {
      throw URLError(.cannotDecodeContentData)
    }
    return HTTPDataResponse(request: updateRequest, data: data, response: response, result: .success(decoded))
  }

  /// Convenience method to upload data using an `HTTPRequestable`, creates and resumes a `URLSessionUploadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to upload data.
  ///   - bodyData: Data to upload.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Data and response.
  func upload<Request: HTTPRequestable>(for request: Request, from bodyData: Data, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPDataResponse<Request.ResultType> {
    logger.trace("[IN]: \(#function)")
    var updateRequest = try request.httpRequest
    for interceptor in requestInterceptors {
      try await interceptor.intercept(&updateRequest, for: session)
    }
    let (data, response) = try await session.upload(for: updateRequest, from: bodyData, delegate: delegate)
    for interceptor in responseInterceptors {
      try await interceptor.intercept(request: updateRequest, data: data, url: nil, response: response)
    }
    if let error = response.error {
      return HTTPDataResponse(request: updateRequest, data: data, response: response, result: .failure(error))
    }
    guard let decoded = try request.responseDataTransformer?(data) else {
      throw URLError(.cannotDecodeContentData)
    }
    return HTTPDataResponse(request: updateRequest, data: data, response: response, result: .success(decoded))
  }

  /// Convenience method to download using an `HTTPRequestable`; creates and resumes a `URLSessionDownloadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to download.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Downloaded file URL and response. The file will not be removed automatically.
  func download(for request: some HTTPRequestable, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPDownloadResponse<URL> {
    logger.trace("[IN]: \(#function)")
    var updateRequest = try request.httpRequest
    for interceptor in requestInterceptors {
      try await interceptor.intercept(&updateRequest, for: session)
    }
    let (url, response) = try await session.download(for: updateRequest, delegate: delegate)
    for interceptor in responseInterceptors {
      try await interceptor.intercept(request: updateRequest, data: nil, url: url, response: response)
    }
    if let error = response.error {
      return HTTPDownloadResponse(request: updateRequest, fileURL: url, response: response, result: .failure(error))
    }
    return HTTPDownloadResponse(request: updateRequest, fileURL: url, response: response, result: .success(url))
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
  func object<Request: HTTPRequestable>(for request: Request, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPDataResponse<Request.ResultType> {
    let response = try await data(for: request, delegate: delegate)
    if let error = response.error {
      return HTTPDataResponse(request: response.request, data: response.data, response: response.response, result: .failure(error))
    }
    guard let decoded = try request.responseDataTransformer?(response.data) else {
      throw URLError(.cannotDecodeContentData)
    }
    return HTTPDataResponse(request: response.request, data: response.data, response: response.response, result: .success(decoded))
  }
}
