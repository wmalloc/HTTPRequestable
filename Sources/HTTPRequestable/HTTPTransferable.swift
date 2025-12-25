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

public protocol HTTPTransferable: AnyObject, HTTPTransportable, Sendable {
  var session: URLSession { get }

  /// Request Modifiers
  var requestModifiers: [any HTTPRequestModifier] { get async }

  /// Response Interceptors
  var interceptors: [any HTTPInterceptor] { get async }
}

/// Default implementations of the protocol
extension HTTPTransferable {
  /// Request to sent to server
  /// - Parameter request: Description of the request
  /// - Returns: request to be sent to server
  func httpRequest(_ request: some HTTPRequestConvertible) async throws -> HTTPRequest {
    logger.trace("[IN]: \(#function)")
    var updatedRequest = try request.httpRequest
    for try modifier in await requestModifiers {
      try await modifier.modify(&updatedRequest, for: session)
    }
    return updatedRequest
  }

  /// Sends the given HTTP request through the provided interceptor chain and returns the resulting response.
  ///
  /// This method applies the registered interceptors to the provided request in reverse order, wrapping each one around the provided `interceptor` closure.
  /// The resulting chain is then executed asynchronously, allowing each interceptor to observe and modify the request or response as needed before ultimately
  /// forwarding the response back to the caller.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequest` to send through the interceptor chain.
  ///   - next: The terminal closure that is called to perform the actual network operation. This closure receives the (potentially modified)
  ///   - delegate: An optional `URLSessionTaskDelegate` that allows customization of the request and response behavior. If not provided, a default delegate will be used.
  /// request and returns an `HTTPAnyResponse` asynchronously. Interceptors can call this closure to forward the request and receive the response.
  ///
  /// - Returns: An `HTTPAnyResponse` containing the data and metadata received from the server after all interceptors have been applied.
  ///
  /// - Throws: Any error thrown by an interceptor or during the final network operation. Errors propagate up through the interceptor chain.
  ///
  /// - Note: Interceptors are processed in reverse order so that the first interceptor in the array is the last to execute before the network request is made.
  func send(request: HTTPRequest, next interceptor: HTTPInterceptor.Next, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPAnyResponse {
    logger.trace("[IN]: \(#function)")
    return try await session.send(request: request, next: interceptor, interceptors: interceptors, delegate: delegate)
  }
}

/// Default implementations of the protocol
public extension HTTPTransferable {
  /// Send the request and get the raw data back
  /// - Parameters:
  ///   - request: The `HTTPRequest` for which to load data.
  ///   - httpBody: httpbody, defaults to nil
  ///   - delegate: Task-specific delegate. defaults to nil
  /// - Returns: Data and response.
  func data(for request: HTTPRequest, httpBody body: Data? = nil, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPAnyResponse {
    let next: HTTPInterceptor.Next = {
      try await self.session.data(for: $0, httpBody: body, delegate: $1)
    }
    return try await send(request: request, next: next, delegate: delegate)
  }

  /// Send the request and get the raw data back
  /// - Parameters:
  ///   - request: The `HTTPRequestConfigurable` for which to load data.
  ///   - delegate: Task-specific delegate. defaults to nil
  /// - Returns: Data and response.
  func data(for request: some HTTPRequestConfigurable, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPAnyResponse {
    logger.trace("[IN]: \(#function)")
    return try await data(for: httpRequest(request), httpBody: request.httpBody, delegate: delegate)
  }

  /// Convenience method to upload data using an `HTTPRequestConvertible`; creates and resumes a `URLSessionUploadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestConvertible` for which to upload data.
  ///   - fileURL: File to upload.
  ///   - delegate: Task-specific delegate. defaults to nil
  /// - Returns: Data and response.
  func upload(for request: some HTTPRequestConvertible, fromFile fileURL: URL, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPAnyResponse {
    logger.trace("[IN]: \(#function)")
    let updatedRequest = try await httpRequest(request)
    let next: HTTPInterceptor.Next = {
      let (data, response) = try await self.session.upload(for: updatedRequest, fromFile: fileURL, delegate: $1)
      return HTTPAnyResponse(request: $0, response: response, data: data)
    }
    return try await send(request: updatedRequest, next: next, delegate: delegate)
  }

  /// Convenience method to upload data using an `HTTPRequestConvertible`, creates and resumes a `URLSessionUploadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestConvertible` for which to upload data.
  ///   - bodyData: Data to upload.
  ///   - delegate: Task-specific delegate. defaults to nil
  /// - Returns: Data and response.
  func upload(for request: some HTTPRequestConvertible, from bodyData: Data, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPAnyResponse {
    logger.trace("[IN]: \(#function)")
    let updatedRequest = try await httpRequest(request)
    let next: HTTPInterceptor.Next = {
      let (data, response) = try await self.session.upload(for: $0, from: bodyData, delegate: $1)
      return HTTPAnyResponse(request: $0, response: response, data: data)
    }
    return try await send(request: updatedRequest, next: next, delegate: delegate)
  }

  /// Convenience method to upload data using an `HTTPRequestConfigurable`, creates and resumes a `URLSessionUploadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestConfigurable` for which to upload data.
  ///   - multipartForm: Data to upload.
  ///   - delegate: Task-specific delegate. defaults to nil
  /// - Returns: Data and response.
  func upload(for request: some HTTPRequestConfigurable, multipartForm: MultipartForm, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPAnyResponse {
    let contentType = multipartForm.contentType
    let contentLength = multipartForm.contentLength
    let updatedRequest = request.append(headerField: HTTPField(name: .contentLength, value: "\(contentLength)"))
      .append(headerField: HTTPField(name: .contentType, value: contentType.encoded))

    if contentLength <= MultipartForm.encodingMemoryThreshold {
      /// if we have enough memory to store data
      let data = try multipartForm.data(streamBufferSize: multipartForm.streamBufferSize)
      return try await upload(for: updatedRequest, from: data, delegate: delegate)
    } else {
      /// write the data to file and upload the file
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
  ///   - delegate: Task-specific delegate. defaults to nil
  /// - Returns: Downloaded file URL and response. The file will not be removed automatically.
  func download(for request: some HTTPRequestConvertible, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPAnyResponse {
    logger.trace("[IN]: \(#function)")
    let updatedRequest = try await httpRequest(request)
    let next: HTTPInterceptor.Next = {
      let (url, response) = try await self.session.download(for: updatedRequest, delegate: $1)
      return HTTPAnyResponse(request: $0, response: response, data: nil, fileURL: url)
    }
    return try await send(request: updatedRequest, next: next, delegate: delegate)
  }

  /// Returns a byte stream that conforms to AsyncSequence protocol.
  /// - Parameters:
  ///   - request: The `HTTPRequestConvertible` for which to load data.
  ///   - delegate: Task-specific delegate. defaults to nil
  /// - Returns: Data stream and response.
  @inlinable
  func bytes(for request: some HTTPRequestConvertible, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> (URLSession.AsyncBytes, HTTPResponse) {
    try await session.bytes(for: request, delegate: delegate)
  }

  /**
   Make a request call and return decoded data as decoded by the transformer, this requesst must return data

   - Parameters:
     - request: Request where to get the data from
     - delegate: Delegate to handle the request, defaults to nil
   - returns: Transformed Object
   */
  @inlinable
  func object<R: HTTPRequestConfigurable>(for request: R, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> R.ResultType {
    try await data(for: request, delegate: delegate)
      .transformed(using: request.responseDataTransformer)
  }
}

extension FileManager {
  func tempFile() throws -> URL {
    let directoryURL = temporaryDirectory.appendingPathComponent("com.waqarmalik.HTTPTransferable/multipart.form.data")
    let fileName = UUID().uuidString
    let fileURL = directoryURL.appendingPathComponent(fileName)
    try createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
    return fileURL
  }
}
