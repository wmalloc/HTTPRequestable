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

public protocol HTTPTransferable: Sendable, AnyObject, Actor {
  var session: URLSession { get }

  /// Request Modifiers
  var requestModifiers: [any HTTPRequestModifier] { get set }

  /// Response Interceptors
  var interceptors: [any HTTPInterceptor] { get set }

  init(session: URLSession)

  /// Request to sent to server
  /// - Parameter request: Description of the request
  /// - Returns: request to be sent to server
  func httpRequest(_ request: some HTTPRequestable) async throws -> HTTPRequest

  /// Performs a network request and returns the raw response.
  ///
  /// This method is part of an asynchronous networking layer that sends an `HTTPRequest`
  /// (a type‑aliased wrapper around `URLRequest`) using `URLSession`.
  ///
  /// The caller can provide an optional HTTP body (`Data?`) and an optional task delegate.
  /// If a delegate is supplied, it will be used for the created `URLSessionTask`; otherwise,
  /// the default delegate of the session is used.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequest` to send. This includes the URL, method, headers, etc.
  ///   - body: Optional raw HTTP body data that will be attached to the request.
  ///     If `nil`, no body is added.
  ///   - delegate: An optional object conforming to `URLSessionTaskDelegate`.
  ///     It is used for task‑level callbacks such as authentication challenges or progress updates.
  /// - Returns: A value of type `HTTPAnyResponse`, which encapsulates the status code,
  ///   headers, and raw data returned by the server. The caller can then decode
  ///   this response into a more specific model if desired.
  /// - Throws:
  ///   - Any error thrown by `URLSession` during task creation or execution.
  ///   - Network‑level errors such as connection failures or timeouts.
  ///
  /// Example usage:
  ///
  /// ```swift
  /// let request = HTTPRequest(url: URL(string: "https://api.example.com")!)
  /// do {
  ///     let response = try await client.data(for: request, httpBody: nil, delegate: nil)
  ///     // Handle `response`
  /// } catch {
  ///     print("Network error:", error)
  /// }
  /// ```
  ///
  /// This method is designed to be called from an asynchronous context (`async/await`)
  /// and will automatically propagate any networking errors up the call chain.
  func data(for request: HTTPRequest, httpBody body: Data?, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPAnyResponse

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
    for try modifier in requestModifiers {
      try await modifier.modify(&updatedRequest, for: session)
    }
    return updatedRequest
  }

  /// Send the request and get the raw data back
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to load data.
  ///   - httpBody: httpbody, defaults to nil
  ///   - delegate: Task-specific delegate. defaults to nil
  /// - Returns: Data and response.
  func data(for request: HTTPRequest, httpBody body: Data? = nil, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPAnyResponse {
    logger.trace("[IN]: \(#function)")
    let (data, httpResponse) = if let body {
      try await session.upload(for: request, from: body, delegate: delegate)
    } else {
      try await session.data(for: request, delegate: delegate)
    }
    return HTTPAnyResponse(request: request, response: httpResponse, data: data)
  }

  /// Send the request and get the raw data back
  /// - Parameters:
  ///   - request: The `HTTPRequestable` for which to load data.
  ///   - delegate: Task-specific delegate. defaults to nil
  /// - Returns: Data and response.
  func data(for request: some HTTPRequestable, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPAnyResponse {
    logger.trace("[IN]: \(#function)")
    let updatedRequest = try await httpRequest(request)
    var response = try await data(for: updatedRequest, httpBody: request.httpBody, delegate: delegate)
    for try interceptor in interceptors.reversed() {
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
    for try interceptor in interceptors.reversed() {
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
    for try interceptor in interceptors.reversed() {
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
    for try interceptor in interceptors.reversed() {
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
    let updatedRequest = try await httpRequest(request)
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
