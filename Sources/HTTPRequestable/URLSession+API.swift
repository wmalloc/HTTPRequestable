//
//  URLSession+API.swift
//
//  Created by Waqar Malik on 1/24/25.
//

import Foundation
import HTTPTypes
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension URLSession {
  /// Sends the given HTTP request through the provided interceptor chain and returns the resulting response.
  ///
  /// Wraps `send` in `interceptors` and runs the chain. The first interceptor is the outermost: it sees
  /// the request first and the response last.
  ///
  /// Before `send` runs, the request the interceptors forward is checked against the one that entered the
  /// chain, using the redirect policy of `delegate` (see ``HTTPRedirectPolicy/forwardedRequest(_:original:)``),
  /// and the delegate they forward is combined with `delegate`'s redirect policy, pins and response size
  /// limit (see `chainedTaskDelegate(_:caller:)`). Both come from the caller's delegate, not one an
  /// interceptor substitutes, so an interceptor cannot relax them.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequest` to send through the interceptor chain.
  ///   - send: The terminal closure that performs the network operation with the (potentially modified) request.
  ///   - interceptors: The interceptors to run, outermost first. Defaults to none.
  ///   - delegate: An optional `URLSessionTaskDelegate` that allows customization of the request and response behavior. If not provided, a default delegate will be used.
  ///
  /// - Returns: An `HTTPClientResponse` containing the data and metadata received from the server after all interceptors have been applied.
  ///
  /// - Throws: Any error thrown by an interceptor or during the final network operation, or
  ///   `URLError(.appTransportSecurityRequiresSecureConnection)` when an interceptor moves an `https`
  ///   request to another scheme. Errors propagate up through the interceptor chain.
  func performRequest(_ request: HTTPRequest, next send: @escaping HTTPInterceptor.NextHandler,
                      interceptors: some Sequence<any HTTPInterceptor> = [],
                      delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPClientResponse
  {
    let policy = Self.redirectPolicy(of: delegate)
    var next: HTTPInterceptor.NextHandler = { forwarded, forwardedDelegate in
      try await send(policy.forwardedRequest(forwarded, original: request),
                     Self.chainedTaskDelegate(forwardedDelegate, caller: delegate))
    }
    for interceptor in interceptors.reversed() {
      let _next = next
      next = {
        try await interceptor.intercept($0, next: _next, delegate: $1)
      }
    }
    return try await next(request, delegate)
  }
}

extension URLSession: HTTPTransportable {
  public func performRequest(_ request: HTTPRequest, httpBody body: Data? = nil, retryPolicy: RetryPolicy? = nil,
                             delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPClientResponse
  {
    var attempt = 0
    var generator = SystemRandomNumberGenerator()
    let taskDelegate = Self.secureTaskDelegate(delegate)
    let maxResponseSize = Self.maxResponseSize(of: taskDelegate)
    let retryPolicy = retryPolicy.flatMap { $0.allowsRetry(for: request.method) ? $0 : nil }

    while true {
      let clientResponse: HTTPClientResponse
      do {
        let (data, response) = try await load(request, httpBody: body, maxResponseSize: maxResponseSize, delegate: taskDelegate)
        clientResponse = HTTPClientResponse(request: request, requestBody: body.map(HTTPClientResponse.Body.data) ?? .empty,
                                            response: response, responseData: data)
      } catch {
        guard let retryPolicy, retryPolicy.shouldRetry(error: error, attempt: attempt) else {
          throw error
        }
        try await Task.sleep(for: .seconds(retryPolicy.retryDelay(for: attempt, using: &generator)))
        attempt += 1
        continue
      }

      // A retryable status such as 503 is retried; once the retries are used up, the last response is
      // returned as it is, for the caller to validate.
      guard let retryPolicy, let delay = retryPolicy.retryDelay(after: clientResponse.response, attempt: attempt, now: Date(), using: &generator) else {
        return clientResponse
      }
      try await Task.sleep(for: .seconds(delay))
      attempt += 1
    }
  }

  /// Sends `request` once and loads the whole response body.
  ///
  /// With a `maxResponseSize`, the body is streamed and the request fails as soon as it is exceeded. The
  /// limit is only available on Apple platforms, where ``HTTPSecurityDelegate`` provides it.
  private func load(_ request: HTTPRequest, httpBody body: Data?, maxResponseSize: Int?,
                    delegate: any URLSessionTaskDelegate) async throws -> (Data, HTTPResponse)
  {
    #if canImport(Darwin)
    if let maxResponseSize {
      return try await limitedData(for: request, httpBody: body, maxResponseSize: maxResponseSize, delegate: delegate)
    }
    #endif
    if let body {
      return try await upload(for: request, from: body, delegate: delegate)
    }
    return try await data(for: request, delegate: delegate)
  }

  // `URLSession.AsyncBytes`, which streaming the body needs, exists only on Apple platforms.
  #if canImport(Darwin)
  /// Loads the response body into memory, failing as soon as it exceeds `maxResponseSize` bytes instead
  /// of buffering all of it.
  ///
  /// - Throws: `URLError(.dataLengthExceedsMaximum)` when the declared or received length is too large.
  func limitedData(for request: HTTPRequest, httpBody body: Data?, maxResponseSize: Int,
                   delegate: any URLSessionTaskDelegate) async throws -> (Data, HTTPResponse)
  {
    guard var urlRequest = URLRequest(httpRequest: request) else {
      throw HTTPError.cannotCreateURLRequest
    }
    urlRequest.httpBody = body
    let (bytes, urlResponse) = try await bytes(for: urlRequest, delegate: delegate)
    guard let response = (urlResponse as? HTTPURLResponse)?.httpResponse else {
      bytes.task.cancel()
      throw HTTPError.cannotConvertToHTTPResponse
    }

    let expectedLength = urlResponse.expectedContentLength
    guard expectedLength <= Int64(maxResponseSize) else {
      bytes.task.cancel()
      throw URLError(.dataLengthExceedsMaximum)
    }

    var data = Data()
    data.reserveCapacity(expectedLength > 0 ? Int(expectedLength) : 0)
    for try await byte in bytes {
      guard data.count < maxResponseSize else {
        bytes.task.cancel()
        throw URLError(.dataLengthExceedsMaximum)
      }
      data.append(byte)
    }
    return (data, response)
  }
  #endif

  /// Request data from server
  /// - Parameters:
  ///   - request:  Request where to get the data from
  ///   - delegate: Delegate to handle the request
  /// - Returns: Data, and HTTPResponse
  public func performRequest(_ request: some HTTPRequestConfigurable, retryPolicy: RetryPolicy? = nil, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPClientResponse {
    try await performRequest(request.httpRequest, httpBody: request.httpBody, retryPolicy: retryPolicy, delegate: delegate)
  }

  /// Convenience method to upload data using an `HTTPRequestConvertible`; creates and resumes a `URLSessionUploadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestConvertible` for which to upload data.
  ///   - fileURL: File to upload.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Data and response.
  public func upload(for request: some HTTPRequestConvertible, fromFile fileURL: URL, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPClientResponse {
    let updateRequest = try request.httpRequest
    let (data, response) = try await upload(for: updateRequest, fromFile: fileURL, delegate: Self.secureTaskDelegate(delegate))
    return HTTPClientResponse(request: updateRequest, requestBody: .file(fileURL), response: response, responseData: data)
  }

  /// Convenience method to upload data using an `HTTPRequestConvertible`, creates and resumes a `URLSessionUploadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestConvertible` for which to upload data.
  ///   - bodyData: Data to upload.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Data and response.
  public func upload(for request: some HTTPRequestConvertible, from bodyData: Data, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPClientResponse {
    let updateRequest = try request.httpRequest
    let (data, response) = try await upload(for: updateRequest, from: bodyData, delegate: Self.secureTaskDelegate(delegate))
    return HTTPClientResponse(request: updateRequest, requestBody: .data(bodyData), response: response, responseData: data)
  }

  /// Convenience method to upload data using an `HTTPRequestConfigurable`, creates and resumes a `URLSessionUploadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestConfigurable` for which to upload data.
  ///   - multipartForm: Data to upload in multipart form.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Data and response.
  public func upload(for request: some HTTPRequestConfigurable, multipartForm: MultipartForm, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPClientResponse {
    let contentType = multipartForm.contentType
    let updatedRequest = request.appendHeaderField(HTTPField(name: .contentType, value: contentType.encoded))

    if multipartForm.contentLength <= MultipartForm.encodingMemoryThreshold {
      // if we have enough memory to store data
      let data = try multipartForm.data(streamBufferSize: multipartForm.streamBufferSize)
      return try await upload(for: updatedRequest, from: data, delegate: delegate)
    }
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

  /// Convenience method to download using an `HTTPRequestConvertible`; creates and resumes a `URLSessionDownloadTask` internally.
  /// - Parameters:
  ///   - request: The `HTTPRequestConvertible` for which to download.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Downloaded file URL and response. The file will not be removed automatically.
  public func download(for request: some HTTPRequestConvertible, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> HTTPClientResponse {
    let updateRequest = try request.httpRequest
    let (url, response) = try await download(for: updateRequest, delegate: Self.secureTaskDelegate(delegate))
    return HTTPClientResponse(request: updateRequest, response: response, responseFileURL: url)
  }

  // `URLSession.AsyncBytes` exists only on Apple platforms.
  #if canImport(Darwin)
  /// Returns a byte stream that conforms to AsyncSequence protocol.
  /// - Parameters:
  ///   - request: The `HTTPRequestConvertible` for which to load data.
  ///   - delegate: Task-specific delegate.
  /// - Returns: Data stream and response.
  public func bytes(for request: some HTTPRequestConvertible, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> (URLSession.AsyncBytes, HTTPResponse) {
    let updateRequest = try request.httpRequest
    return try await bytes(for: updateRequest, delegate: Self.secureTaskDelegate(delegate))
  }
  #endif

  /// Sends `request`, checks the response with the request's `validateResponse(_:)`, and decodes the
  /// body with its `responseDataTransformer`.
  ///
  /// - Parameters:
  ///   - request: The request to send.
  ///   - delegate: Task-specific delegate, defaults to nil.
  /// - Returns: The decoded result.
  /// - Throws: Any error thrown while sending the request, by `validateResponse(_:)` (by default
  ///   `HTTPError.unacceptableStatusCode` for a status outside `2xx`), or by the transformer.
  public func object<R: HTTPRequestConfigurable>(for request: R, delegate: (any URLSessionTaskDelegate)? = nil) async throws -> R.ResultType {
    let response = try await performRequest(request, delegate: delegate)
    try request.validateResponse(response)
    return try response.transformed(using: request.responseDataTransformer)
  }
}
