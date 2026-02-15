//
//  URLSession+API.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 1/24/25.
//

import Foundation
import HTTPTypes
import OSLog

#if DEBUG
private let logger = Logger(.init(subsystem: "com.waqarmalik.HTTPRequestable", category: "URLSesion+API"))
#else
private let logger = Logger(.disabled)
#endif

extension URLSession {
  /// Sends the given HTTP request through the provided interceptor chain and returns the resulting response.
  ///
  /// This method applies the registered interceptors to the provided request in reverse order, wrapping each one around the provided `interceptor` closure.
  /// The resulting chain is then executed asynchronously, allowing each interceptor to observe and modify the request or response as needed before ultimately
  /// forwarding the response back to the caller.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequest` to send through the interceptor chain.
  ///   - next: The terminal closure that is called to perform the actual network operation. This closure receives the (potentially modified)
  ///   - interceptors: A collection of`HTTPInterceptor` that allows customization of the request and response behavior. If not provided, empty array.
  ///   - delegate: An optional `URLSessionTaskDelegate` that allows customization of the request and response behavior. If not provided, a default delegate will be used.
  /// request and returns an `HTTPDataResponse` asynchronously. Interceptors can call this closure to forward the request and receive the response.
  ///
  /// - Returns: An `HTTPDataResponse` containing the data and metadata received from the server after all interceptors have been applied.
  ///
  /// - Throws: Any error thrown by an interceptor or during the final network operation. Errors propagate up through the interceptor chain.
  ///
  /// - Note: Interceptors are processed in reverse order so that the first interceptor in the array is the last to execute before the network request is made.
  func performRequest(_ request: HTTPRequest, next interceptor: HTTPInterceptor.Next, interceptors: any Collection<any HTTPInterceptor> = [],
                      delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPDataResponse {
    logger.trace("[IN]: \(#function)")
    var next = interceptor
    for interceptor in interceptors.reversed() {
      let _next = next
      next = {
        try await interceptor.intercept(for: $0, next: _next, delegate: $1)
      }
    }
    return try await next(request, delegate)
  }
}

extension URLSession: HTTPTransportable {
  public func performRequest(_ request: HTTPRequest, httpBody body: Data?, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPDataResponse {
    logger.trace("[IN]: \(#function)")
    let (data, response) = if let body {
      try await upload(for: request, from: body, delegate: delegate)
    } else {
      try await data(for: request, delegate: delegate)
    }
    return HTTPDataResponse(request: request, response: response, data: data)
  }

  /// Request data from server
  /// - Parameters:
  ///   - request:  Request where to get the data from
  ///   - delegate: Delegate to handle the request
  /// - Returns: Data, and HTTPResponse
  public func performRequest(_ request: some HTTPRequestConfigurable, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPDataResponse {
    logger.trace("[IN]: \(#function)")
    return try await performRequest(request.httpRequest, httpBody: request.httpBody, delegate: delegate)
  }

  /// Convenience method to upload data using an `HTTPRequestConvertible`; creates and resumes a `URLSessionUploadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestConvertible` for which to upload data.
  ///   - fileURL: File to upload.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Data and response.
  public func upload(for request: some HTTPRequestConvertible, fromFile fileURL: URL, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPDataResponse {
    logger.trace("[IN]: \(#function)")
    let updateRequest = try request.httpRequest
    let (data, response) = try await upload(for: updateRequest, fromFile: fileURL, delegate: delegate)
    return HTTPDataResponse(request: updateRequest, response: response, data: data)
  }

  /// Convenience method to upload data using an `HTTPRequestConvertible`, creates and resumes a `URLSessionUploadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestConvertible` for which to upload data.
  ///   - bodyData: Data to upload.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Data and response.
  public func upload(for request: some HTTPRequestConvertible, from bodyData: Data, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPDataResponse {
    logger.trace("[IN]: \(#function)")
    let updateRequest = try request.httpRequest
    let (data, response) = try await upload(for: updateRequest, from: bodyData, delegate: delegate)
    return HTTPDataResponse(request: updateRequest, response: response, data: data)
  }

  /// Convenience method to upload data using an `HTTPRequestConfigurable`, creates and resumes a `URLSessionUploadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestConfigurable` for which to upload data.
  ///   - multipartForm: Data to upload in multipart form.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Data and response.
  public func upload(for request: some HTTPRequestConfigurable, multipartForm: MultipartForm, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPDataResponse {
    logger.trace("[IN]: \(#function)")
    let contentType = multipartForm.contentType
    let contentLength = multipartForm.contentLength
    let updatedRequest = request.append(headerField: HTTPField(name: .contentLength, value: "\(contentLength)"))
      .append(headerField: HTTPField(name: .contentType, value: contentType.encoded))

    if contentLength <= MultipartForm.encodingMemoryThreshold {
      // if we have enough memory to store data
      let data = try multipartForm.data(streamBufferSize: multipartForm.streamBufferSize)
      return try await upload(for: updatedRequest, from: data, delegate: delegate)
    } else {
      // write the data to file and upload the file
      let fileManager = multipartForm.fileManager
      let fileURL = try fileManager.tempFile()
      do {
        try multipartForm.write(encodedDataTo: fileURL, streamBufferSize: multipartForm.streamBufferSize)
        let result = try await upload(for: updatedRequest, fromFile: fileURL, delegate: delegate)
        try? fileManager.removeItem(at: fileURL)
        return result
      } catch {
        // Cleanup after attempted write if it fails.
        try? fileManager.removeItem(at: fileURL)
        throw error
      }
    }
  }

  /// Convenience method to download using an `HTTPRequestConvertible`; creates and resumes a `URLSessionDownloadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestConvertible` for which to download.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Downloaded file URL and response. The file will not be removed automatically.
  public func download(for request: some HTTPRequestConvertible, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPDataResponse {
    logger.trace("[IN]: \(#function)")
    let updateRequest = try request.httpRequest
    let (url, response) = try await download(for: updateRequest, delegate: delegate)
    return HTTPDataResponse(request: updateRequest, response: response, data: Data(), fileURL: url)
  }

  /// Returns a byte stream that conforms to AsyncSequence protocol.
  /// - Parameters:
  ///   - request: The `HTTPRequestConvertible` for which to load data.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Data stream and response.
  public func bytes(for request: some HTTPRequestConvertible, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> (URLSession.AsyncBytes, HTTPResponse) {
    logger.trace("[IN]: \(#function)")
    let updateRequest = try request.httpRequest
    return try await bytes(for: updateRequest, delegate: delegate)
  }

  /**
   Make a request call and return decoded data as decoded by the transformer, this requesst must return data

   - Parameters:
     - request: Request where to get the data from
     - delegate: Delegate to handle the request, defaults to nil
   - returns: Transformed Object
   */
  @inlinable
  public func object<R: HTTPRequestConfigurable>(for request: R, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> R.ResultType {
    try await performRequest(request, delegate: delegate)
      .transformed(using: request.responseDataTransformer)
  }
}
