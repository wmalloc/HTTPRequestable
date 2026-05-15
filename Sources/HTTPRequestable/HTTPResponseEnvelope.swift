//
//  HTTPResponseEnvelope.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 12/14/24.
//  Renamed from HTTPDataResponse on 2026-05-14.
//

import Foundation
import HTTPTypes

public struct HTTPResponseEnvelope: Sendable {
  /// Payload returned by the server.
  public enum Body: Sendable {
    /// An in-memory response body.
    case data(Data)
    /// A response written to disk (e.g. by `URLSessionDownloadTask`).
    case file(URL)
    /// No body was returned.
    case empty
  }

  /// Request that was sent to the server.
  public let request: HTTPRequest

  /// Response received from the server.
  public let response: HTTPResponse

  /// The response payload, modelled as one of: in-memory data, an on-disk file, or empty.
  public let body: Body

  public init(request: HTTPRequest, response: HTTPResponse, body: Body) {
    self.request = request
    self.response = response
    self.body = body
  }

  /// Convenience for an in-memory response.
  public init(request: HTTPRequest, response: HTTPResponse, data: Data) {
    self.init(request: request, response: response, body: data.isEmpty ? .empty : .data(data))
  }

  /// Convenience for a download response.
  public init(request: HTTPRequest, response: HTTPResponse, fileURL: URL) {
    self.init(request: request, response: response, body: .file(fileURL))
  }
}

public extension HTTPResponseEnvelope {
  /// In-memory payload, when the body is `.data`. Empty otherwise.
  var data: Data {
    if case .data(let data) = body { return data }
    return Data()
  }

  /// On-disk payload location, when the body is `.file`.
  var fileURL: URL? {
    if case .file(let url) = body { return url }
    return nil
  }

  /// The response header fields.
  @inlinable
  var headerFields: HTTPFields {
    response.headerFields
  }

  /// The response headers as a multi-value dictionary.
  ///
  /// Multiple values for the same header name (e.g. `Set-Cookie`) are preserved.
  var headers: [String: [String]] {
    response.headerFields.reduce(into: [:]) { partialResult, field in
      partialResult[field.name.rawName, default: []].append(field.value)
    }
  }

  /// If there was a server error
  @inlinable
  var error: Error? {
    response.error
  }

  /// Status code
  @inlinable
  var status: HTTPResponse.Status {
    response.status
  }

  /// if the call was successfull
  @inlinable
  var isSuccessful: Bool {
    response.status.kind == .successful
  }

  /// Reads the downloaded payload from disk when the body is `.file`.
  /// - Returns: The file contents, or `nil` when the body is not a file.
  /// - Throws: Any error raised by `Data(contentsOf:options:)` (e.g. file missing, permissions).
  func fileData() throws -> Data? {
    guard let fileURL else { return nil }
    return try Data(contentsOf: fileURL, options: .mappedIfSafe)
  }

  /// Validates the response and then returns itself.
  ///
  /// The method first checks that the HTTP status code is acceptable, then
  /// verifies that the returned content type matches one of the types listed in
  /// ``acceptContentType``.  If any check fails a throwing error is propagated,
  /// otherwise the same instance (`self`) is returned so callers can chain
  /// further operations.
  ///
  /// - Throws: An error from either ``validateStatus()`` or ``validateContentTypes(_:)-(some)``.
  /// - Returns: `self`, allowing method chaining.
  @discardableResult
  func validate() throws -> Self {
    try validateStatus()
    try validateContentTypes(acceptContentType)
    return self
  }

  /// Validates the result for a given status code.
  /// - Returns: Self if the status code indicates success.
  /// - Throws: ``HTTPError/unacceptableStatusCode(_:)`` when the status is not in the successful range.
  @discardableResult
  func validateStatus() throws -> Self {
    if response.status.kind != .successful {
      throw HTTPError.unacceptableStatusCode(response.status)
    }
    return self
  }

  /// Validates the content type if acceptable content types are given.
  /// - Parameter acceptableContentTypes: Set of acceptable content types, defaults to nil.
  /// - Returns: Self if the content type is acceptable.
  @discardableResult
  func validateContentTypes(_ acceptableContentTypes: some Sequence<String>) throws -> Self {
    let contentTypes = acceptableContentTypes.map(HTTPContentType.init(rawValue:))
    return try validateContentTypes(contentTypes)
  }

  /// Validates the content type if acceptable content types are given.
  /// - Parameter acceptableContentTypes: Set of acceptable content types, defaults to nil.
  /// - Returns: Self if the content type is acceptable.
  @discardableResult
  func validateContentTypes(_ acceptableContentTypes: some Sequence<HTTPContentType>) throws -> Self {
    // Wildcard accepts anything
    if acceptableContentTypes.contains(HTTPContentType.any) {
      return self
    }

    // Ensure the server provided a content type
    guard let contentTypes = response.contentTypes else {
      throw HTTPError.contentTypeHeaderMissing
    }

    // Check if any of the response content types match the acceptable types
    let acceptable = Set(acceptableContentTypes)
    guard !contentTypes.isDisjoint(with: acceptable) else {
      throw HTTPError.invalidContentType
    }

    return self
  }

  /// The set of MIME types this response will accept.
  ///
  /// Returns the value stored in ``HTTPRequest/acceptContentTypes`` or `[.any]`
  /// (the wildcard, accepting everything) when the request does not specify one.
  var acceptContentType: Set<HTTPContentType> {
    request.acceptContentTypes ?? [HTTPContentType.any]
  }
}

public extension HTTPResponseEnvelope {
  /// Transforms the response body with the supplied transformer.
  ///
  /// The bytes are taken from `.data` when the body is in memory, or read from
  /// disk via ``fileData()`` when the body is `.file`. An `.empty` body throws
  /// `URLError(.zeroByteResource)`.
  ///
  /// - Parameter transformer: The closure used to convert raw `Data` into the desired type.
  /// - Returns: The result of applying `transformer` to the response body.
  /// - Throws:
  ///   * `URLError(.zeroByteResource)` when the body is empty.
  ///   * Any error raised while reading a `.file` body from disk.
  ///   * Any error thrown by `transformer`.
  func transformed<ResultType>(using transformer: Transformer<Data, ResultType>) throws -> ResultType {
    let payload: Data
    switch body {
    case .data(let data):
      payload = data
    case .file(let url):
      payload = try Data(contentsOf: url, options: .mappedIfSafe)
    case .empty:
      throw URLError(.zeroByteResource)
    }

    guard !payload.isEmpty else {
      throw URLError(.zeroByteResource)
    }

    return try transformer(payload)
  }
}
