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

/// A contract that enables an object to perform HTTP‑based network
/// operations.
///
/// The protocol is designed for reference types (`AnyObject`) that
/// can be shared across tasks.  It builds on
/// the lower‑level `HTTPTransportable` protocol, adding a session and
/// two asynchronous collections that allow callers to tweak the request
/// before it is sent and to react to the response afterward.
///
/// Typical conformances are view‑model or service objects that need
/// access to a shared `URLSession` and want to provide pluggable
/// behaviour such as logging, authentication, or response‑caching.
public protocol HTTPTransferable: AnyObject, HTTPTransportable {
  /// The `URLSession` used to execute all network requests.
  ///
  /// Conforming types usually provide a shared session (e.g.
  /// `URLSession.shared`) or inject a custom configuration for
  /// testing.  The session is read‑only; any changes should be made
  /// via the initialiser or dependency injection.
  var session: URLSession { get }

  // MARK: Request Modifiers

  /// An array of objects that can mutate an outgoing request.
  ///
  /// Each element must conform to `HTTPRequestModifier`.  The array
  /// is produced asynchronously because the modifiers may need to
  /// perform I/O (e.g. fetch a token from secure storage).
  ///
  /// - Returns: A list of modifiers that will be applied in the
  ///   order they appear.  The default implementation can simply
  ///   return an empty array.
  var requestModifiers: [any HTTPRequestModifier] { get async }

  // MARK: Response Interceptors

  /// An array of objects that can inspect or transform a received
  /// response.
  ///
  /// Each element must conform to `HTTPInterceptor`.  The array is
  /// produced asynchronously for the same reasons as
  /// `requestModifiers`.  Interceptors are invoked after a request
  /// completes, allowing error handling, logging, or response
  /// transformation.
  ///
  /// - Returns: A list of interceptors that will be applied in the
  ///   order they appear.  The default implementation can simply
  ///   return an empty array.
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
    for modifier in await requestModifiers {
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
    let chain = await interceptors
    return try await session.send(request: request, next: interceptor, interceptors: chain, delegate: delegate)
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
      let (data, response) = try await self.session.upload(for: $0, fromFile: fileURL, delegate: $1)
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
  func upload(for request: some HTTPRequestConfigurable, multipartForm: MultipartForm, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPAnyResponse {
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
      let (url, response) = try await self.session.download(for: $0, delegate: $1)
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

  /// Creates an object from the data returned by a request.
  ///
  /// This convenience wrapper combines two steps that are common when
  /// performing network operations:
  ///
  /// 1. It sends the supplied `request` through the underlying
  ///    `URLSession`, optionally using a custom `URLSessionTaskDelegate`.
  /// 2. It transforms the raw `Data` into the type expected by the
  ///    request via the request’s `responseDataTransformer`.
  ///
  /// The function is marked **`@inlinable`** so the compiler can
  /// inline it across module boundaries, improving performance for
  /// small, frequently‑used requests.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequestConfigurable` instance that
  ///     describes the network call.  Its generic `ResultType` is the
  ///     type returned by this method.
  ///   - delegate: An optional `URLSessionTaskDelegate` that can
  ///     intercept callbacks for the underlying task.  If omitted,
  ///     the session’s default delegate is used.
  ///
  /// - Returns: The object obtained by applying
  ///   `request.responseDataTransformer` to the raw data.
  ///
  /// - Throws: Any error thrown by either `data(for:delegate:)` or
  ///   the transformer.  Common errors include network failures,
  ///   decoding errors, and custom validation failures.
  ///
  /// This method is typically used inside a higher‑level service or
  /// repository that hides the details of HTTP communication from its
  /// callers.
  @inlinable
  func object<R: HTTPRequestConfigurable>(for request: R, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> R.ResultType {
    try await data(for: request, delegate: delegate)
      .transformed(using: request.responseDataTransformer)
  }
}
