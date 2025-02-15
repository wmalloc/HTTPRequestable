//
//  HTTPTransferable.swift
//
//
//  Created by Waqar Malik on 11/17/23
//

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

  /// Request to sent to server
  /// - Parameter request: Description of the request
  /// - Returns: request to be sent to server
  func httpRequest(_ request: some HTTPRequestable) async throws -> HTTPRequest

  /// Fetches the data for a given HTTP request using an asynchronous task.
  ///
  /// This method sends the specified `HTTPRequestable` object to a server and waits for the response. The request can optionally include a
  ///  delegate that conforms to `URLSessionTaskDelegate` for customizing the behavior of the request.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequestable` object representing the HTTP request. This protocol defines properties necessary to create an URLRequest.
  ///   - delegate: An optional `URLSessionTaskDelegate` that allows customization of the request and response behavior. If not provided, a default delegate will be used.
  /// - Returns: An `HTTPAnyResponse` object containing the data received from the server in response to the request.
  /// - Throws: An error of type `Error` if the fetch operation fails, such as network issues or invalid requests.
  ///
  /// - Note: The `HTTPRequestable` protocol must be implemented by the request object for this method to work correctly.
  /// - Note: The `HTTPAnyResponse` type can be defined by your application to encapsulate the response data and related information.
  ///
  /// - SeeAlso: `HTTPRequestable`, `HTTPAnyResponse`, `URLSessionTaskDelegate`
  func data(for request: some HTTPRequestable, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPAnyResponse

  /// Uploads a file to the server as part of an HTTP request asynchronously.
  ///
  /// This method sends the specified `HTTPRequestable` object to a server and waits for the response, including file data. The request can
  /// optionally include a delegate that conforms to `URLSessionTaskDelegate` for customizing the behavior of the request.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequestable` object representing the HTTP upload request. This protocol defines properties necessary to create an URLRequest.
  ///   - fileURL: The `URL` of the file to upload.
  ///   - delegate: An optional `URLSessionTaskDelegate` that allows customization of the request and response behavior. If not provided, a default delegate will be used.
  /// - Returns: An `HTTPAnyResponse` object containing the data received from the server in response to the request.
  /// - Throws: An error of type `Error` if the upload operation fails, such as network issues or invalid requests.
  ///
  /// - Note: The `HTTPRequestable` protocol must be implemented by the request object for this method to work correctly.
  /// - Note: The `HTTPAnyResponse` type can be defined by your application to encapsulate the response data and related information.
  ///
  /// - SeeAlso: `HTTPRequestable`, `HTTPAnyResponse`, `URLSessionTaskDelegate`
  func upload(for request: some HTTPRequestable, fromFile fileURL: URL, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPAnyResponse

  /// Uploads data to the server as part of an HTTP request asynchronously.
  ///
  /// This method sends the specified `HTTPRequestable` object to a server and waits for the response, including data body. The request can optionally include a delegate
  /// that conforms to `URLSessionTaskDelegate` for customizing the behavior of the request.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequestable` object representing the HTTP upload request. This protocol defines properties necessary to create an URLRequest.
  ///   - bodyData: The data body to upload.
  ///   - delegate: An optional `URLSessionTaskDelegate` that allows customization of the request and response behavior. If not provided, a default delegate will be used.
  /// - Returns: An `HTTPAnyResponse` object containing the data received from the server in response to the request.
  /// - Throws: An error of type `Error` if the upload operation fails, such as network issues or invalid requests.
  ///
  /// - Note: The `HTTPRequestable` protocol must be implemented by the request object for this method to work correctly.
  /// - Note: The `HTTPAnyResponse` type can be defined by your application to encapsulate the response data and related information.
  ///
  /// - SeeAlso: `HTTPRequestable`, `HTTPAnyResponse`, `URLSessionTaskDelegate`
  func upload(for request: some HTTPRequestable, from bodyData: Data, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPAnyResponse

  /// Convenience method to download using an `HTTPRequestable`; creates and resumes a `URLSessionDownloadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to download.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Downloaded file URL and response. The file will not be removed automatically.
  func download(for request: some HTTPRequestable, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPAnyResponse

  /// Downloads data from the server as part of an HTTP request asynchronously.
  ///
  /// This method sends the specified `HTTPRequestable` object to a server and waits for the response, including file data. The request can optionally include a delegate
  /// that conforms to `URLSessionTaskDelegate` for customizing the behavior of the request.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequestable` object representing the HTTP download request. This protocol defines properties necessary to create an URLRequest.
  ///   - delegate: An optional `URLSessionTaskDelegate` that allows customization of the request and response behavior. If not provided, a default delegate will be used.
  /// - Returns: An `HTTPAnyResponse` object containing the data received from the server in response to the request.
  /// - Throws: An error of type `Error` if the download operation fails, such as network issues or invalid requests.
  ///
  /// - Note: The `HTTPRequestable` protocol must be implemented by the request object for this method to work correctly.
  /// - Note: The `HTTPAnyResponse` type can be defined by your application to encapsulate the response data and related information.
  ///
  /// - SeeAlso: `HTTPRequestable`, `HTTPAnyResponse`, `URLSessionTaskDelegate`
  func bytes(for request: some HTTPRequestable, delegate: (any URLSessionTaskDelegate)?) async throws -> (URLSession.AsyncBytes, HTTPResponse)

  /// Sends an HTTP request and returns the parsed object of type `Request.ResultType` asynchronously.
  ///
  /// This method sends the specified `HTTPRequestable` object to a server and waits for the response. The request can optionally include a delegate
  ///  that conforms to `URLSessionTaskDelegate` for customizing the behavior of the request. The response data is then parsed into an object of type `Request.ResultType`.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequestable` object representing the HTTP request. This protocol defines properties necessary to create an URLRequest and also specifies the type of the resulting object `ResultType`.
  ///   - delegate: An optional `URLSessionTaskDelegate` that allows customization of the request and response behavior. If not provided, a default delegate will be used.
  /// - Returns: An object of type `Request.ResultType` which is the parsed response from the server.
  /// - Throws: An error of type `Error` if the fetch operation fails, such as network issues or invalid requests.
  ///
  /// - Note: The `HTTPRequestable` protocol must be implemented by the request object for this method to work correctly.
  /// - Note: The `ResultType` must be defined by the request object and represents the type of the resulting object after parsing.
  ///
  /// - SeeAlso: `HTTPRequestable`, `URLSessionTaskDelegate`
  func object<Request: HTTPRequestable>(for request: Request, delegate: (any URLSessionTaskDelegate)?) async throws -> Request.ResultType
}

/// Default implementations of the protocol
public extension HTTPTransferable {
  /// Request to sent to server
  /// - Parameter request: Description of the request
  /// - Returns: request to be sent to server
  func httpRequest(_ request: some HTTPRequestable) async throws -> HTTPRequest {
    var updatedRequest = try request.httpRequest
    for interceptor in requestInterceptors {
      try await interceptor.intercept(&updatedRequest, for: session)
    }
    return updatedRequest
  }

  /// Send the request and get the raw data back
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to load data.
  ///   - delegate: Task-specific delegate. defaults to nil
  /// - Returns: Data and response.
  func data(for request: some HTTPRequestable, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPAnyResponse {
    logger.trace("[IN]: \(#function)")
    let updatedRequest = try await httpRequest(request)
    let (data, httpResponse) = if let bodyData = request.httpBody {
      try await session.upload(for: updatedRequest, from: bodyData, delegate: delegate)
    } else {
      try await session.data(for: updatedRequest, delegate: delegate)
    }
    var response = HTTPAnyResponse(request: updatedRequest, response: httpResponse, data: data)
    for interceptor in responseInterceptors.reversed() {
      try await interceptor.intercept(&response, for: session)
    }
    return response
  }

  /// Convenience method to upload data using an `HTTPRequestable`; creates and resumes a `URLSessionUploadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to upload data.
  ///   - fileURL: File to upload.
  ///   - delegate: Task-specific delegate. defaults to nil
  /// - Returns: Data and response.
  func upload(for request: some HTTPRequestable, fromFile fileURL: URL, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPAnyResponse {
    logger.trace("[IN]: \(#function)")
    let updatedRequest = try await httpRequest(request)
    let (data, response) = try await session.upload(for: updatedRequest, fromFile: fileURL, delegate: delegate)
    var result = HTTPAnyResponse(request: updatedRequest, response: response, data: data)
    for interceptor in responseInterceptors.reversed() {
      try await interceptor.intercept(&result, for: session)
    }
    return result
  }

  /// Convenience method to upload data using an `HTTPRequestable`, creates and resumes a `URLSessionUploadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to upload data.
  ///   - bodyData: Data to upload.
  ///   - delegate: Task-specific delegate. defaults to nil
  /// - Returns: Data and response.
  func upload(for request: some HTTPRequestable, from bodyData: Data, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPAnyResponse {
    logger.trace("[IN]: \(#function)")
    let updatedRequest = try await httpRequest(request)
    let (data, response) = try await session.upload(for: updatedRequest, from: bodyData, delegate: delegate)
    var result = HTTPAnyResponse(request: updatedRequest, response: response, data: data)
    for interceptor in responseInterceptors.reversed() {
      try await interceptor.intercept(&result, for: session)
    }
    return result
  }

  /// Convenience method to download using an `HTTPRequestable`; creates and resumes a `URLSessionDownloadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to download.
  ///   - delegate: Task-specific delegate. defaults to nil
  /// - Returns: Downloaded file URL and response. The file will not be removed automatically.
  func download(for request: some HTTPRequestable, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPAnyResponse {
    logger.trace("[IN]: \(#function)")
    let updatedRequest = try await httpRequest(request)
    let (url, response) = try await session.download(for: updatedRequest, delegate: delegate)
    var result = HTTPAnyResponse(request: updatedRequest, response: response, fileURL: url)
    for interceptor in responseInterceptors.reversed() {
      try await interceptor.intercept(&result, for: session)
    }
    return result
  }

  /// Returns a byte stream that conforms to AsyncSequence protocol.
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to load data.
  ///   - delegate: Task-specific delegate. defaults to nil
  /// - Returns: Data stream and response.
  func bytes(for request: some HTTPRequestable, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> (URLSession.AsyncBytes, HTTPResponse) {
    logger.trace("[IN]: \(#function)")
    var updatedRequest = try request.httpRequest
    for interceptor in requestInterceptors {
      try await interceptor.intercept(&updatedRequest, for: session)
    }
    return try await session.bytes(for: updatedRequest, delegate: delegate)
  }

  /**
   Make a request call and return decoded data as decoded by the transformer, this requesst must return data

   - Parameters:
     - route:    Request where to get the data from
     - delegate: Delegate to handle the request, defaults to nil
   - returns: Transformed Object
   */
  @inlinable
  func object<Request: HTTPRequestable>(for request: Request, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> Request.ResultType {
    try await data(for: request, delegate: delegate)
      .transformed(using: request.responseDataTransformer)
  }
}
