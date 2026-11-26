//
//  HTTPClientResponse.swift
//
//  Created by Waqar Malik on 12/14/24.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import HTTPTypes

public struct HTTPClientResponse: Sendable {
  /// An HTTP message payload.
  public enum Body: Sendable {
    /// An in-memory body.
    case data(Data)
    /// A body stored on disk (e.g. a `URLSessionDownloadTask` result or an uploaded file).
    case file(URL)
    /// No body.
    case empty
  }

  /// Request that was sent to the server.
  public let request: HTTPRequest

  /// The payload that was sent with the request, or `.empty` when the request had no body.
  ///
  /// For file uploads this is `.file`; note the referenced file may have been a
  /// temporary one (e.g. large multipart forms) and might no longer exist.
  public let requestBody: Body

  /// Response received from the server.
  public let response: HTTPResponse

  /// The response payload, modelled as one of: in-memory data, an on-disk file, or empty.
  public let responseBody: Body

  public init(request: HTTPRequest, requestBody: Body = .empty, response: HTTPResponse, responseBody: Body) {
    self.request = request
    self.requestBody = requestBody
    self.response = response
    self.responseBody = responseBody
  }

  /// Convenience for an in-memory response.
  public init(request: HTTPRequest, requestBody: Body = .empty, response: HTTPResponse, responseData: Data) {
    self.init(request: request, requestBody: requestBody, response: response, responseBody: responseData.isEmpty ? .empty : .data(responseData))
  }

  /// Convenience for a download response.
  public init(request: HTTPRequest, requestBody: Body = .empty, response: HTTPResponse, responseFileURL: URL) {
    self.init(request: request, requestBody: requestBody, response: response, responseBody: .file(responseFileURL))
  }
}

public extension HTTPClientResponse {
  /// In-memory payload, when the response body is `.data`. Empty otherwise.
  var responseData: Data {
    if case .data(let responseData) = responseBody {
      return responseData
    }
    return Data()
  }

  /// On-disk payload location, when the response body is `.file`.
  var responseFileURL: URL? {
    if case .file(let url) = responseBody {
      return url
    }
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
  func responseFileData() throws -> Data? {
    guard let responseFileURL else { return nil }
    return try Data(contentsOf: responseFileURL, options: .mappedIfSafe)
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

  /// Checks that the response's `Content-Type` is in one of the acceptable media ranges.
  ///
  /// - Parameter acceptableContentTypes: The acceptable media ranges, such as `application/json` or
  ///   `text/*`. Strings that are not valid media ranges are left out, so they accept nothing.
  /// - Returns: `self`.
  /// - Throws: The errors of the overload that takes `HTTPContentType` values.
  @discardableResult
  func validateContentTypes(_ acceptableContentTypes: some Sequence<String>) throws -> Self {
    try validateContentTypes(acceptableContentTypes.compactMap(HTTPContentType.init(rawValue:)))
  }

  /// Checks that the response's `Content-Type` is in one of the acceptable media ranges.
  ///
  /// A range matches by type and subtype, ignoring parameters and case, so `application/json` accepts
  /// `application/json; charset=utf-8`. `*/*` accepts any response, even one without `Content-Type`.
  ///
  /// - Parameter acceptableContentTypes: The acceptable media ranges, such as `application/json` or
  ///   `text/*`. When empty, nothing is acceptable.
  /// - Returns: `self`.
  /// - Throws: `HTTPError.contentTypeHeaderMissing` when the response has no `Content-Type`, or
  ///   `HTTPError.invalidContentType` when it is not a valid media type or is in none of the ranges.
  @discardableResult
  func validateContentTypes(_ acceptableContentTypes: some Sequence<HTTPContentType>) throws -> Self {
    let acceptable = Array(acceptableContentTypes)
    if acceptable.contains(HTTPContentType.any) {
      return self
    }

    guard let raw = response.headerFields[.contentType], !raw.trimmingCharacters(in: .whitespaces).isEmpty else {
      throw HTTPError.contentTypeHeaderMissing
    }
    guard let contentType = HTTPContentType(rawValue: raw), acceptable.contains(where: { $0.matches(contentType) }) else {
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

public extension HTTPClientResponse {
  /// Transforms the response body with the supplied transformer.
  ///
  /// The bytes are taken from `.data` when the body is in memory, or read from
  /// disk via ``responseFileData()`` when the body is `.file`. An empty or `.empty` body is passed as
  /// empty `Data`, so a `Void`, `Data` or `String` result can come from a `204 No Content` response;
  /// the default `Decodable` transformer throws `URLError(.zeroByteResource)` for it.
  ///
  /// - Parameter transformer: The closure used to convert raw `Data` into the desired type.
  /// - Returns: The result of applying `transformer` to the response body.
  /// - Throws:
  ///   * Any error raised while reading a `.file` body from disk.
  ///   * Any error thrown by `transformer`.
  func transformed<ResultType>(using transformer: Transformer<Data, ResultType>) throws -> ResultType {
    let payload: Data
    switch responseBody {
    case .data(let responseData):
      payload = responseData

    case .file(let url):
      payload = try Data(contentsOf: url, options: .mappedIfSafe)

    case .empty:
      payload = Data()
    }

    return try transformer(payload)
  }
}
