//
//  HTTPAnyResponse.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 12/14/24.
//

import Foundation
import HTTPTypes

/// Raw response from the api call
@frozen
public struct HTTPAnyResponse: Hashable, Sendable {
  /// Request that was sent to the server
  public let request: HTTPRequest

  /// Response from the server
  public let response: HTTPResponse

  /// Data returned from the call can be nil if the url was returned
  public var data: Data?

  /// file url where the item was downloaded
  public var fileURL: URL?

  /// Default initalizer
  /// - Parameters:
  ///   - request: The request that was sent to server
  ///   - response: http response from the server
  ///   - data: data if url was not the response
  ///   - fileURL: fileurl if downloading the file
  public init(request: HTTPRequest, response: HTTPResponse, data: Data? = nil, fileURL: URL? = nil) {
    self.request = request
    self.response = response
    self.data = data
    self.fileURL = fileURL
  }
}

public extension HTTPAnyResponse {
  /// The response header fields.
  @inlinable
  var headerFields: HTTPFields {
    response.headerFields
  }

  /// The response headers.
  var headers: [String: String] {
    response.headerFields.reduce(into: [:]) { partialResult, field in
      partialResult[field.name.rawName] = field.value
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

  /// Validates the response and then returns itself.
  ///
  /// The method first checks that the HTTP status code is acceptable, then
  /// verifies that the returned content type matches one of the types listed in
  /// ``acceptContentType``.  If any check fails a throwing error is propagated,
  /// otherwise the same instance (`self`) is returned so callers can chain
  /// further operations.
  ///
  /// The `@discardableResult` attribute keeps the compiler quiet if the caller
  /// doesn’t need the returned value (e.g., when just performing validation).
  ///
  /// - Throws: An error from either ``validateStatus()`` or
  ///   ``validateContentType(_:)``.
  /// - Returns: `self`, allowing method chaining.
  @discardableResult
  func validate() throws -> Self {
    try validateStatus()
      .validateContentTypes(acceptContentType)
  }

  /// Validates the result for a given status code.
  /// - Returns: Self if the status code indicates success.
  @discardableResult
  func validateStatus() throws -> Self {
    if response.status.kind != .successful {
      let errorCode = URLError.Code(rawValue: response.status.code)
      throw URLError(errorCode)
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
    if acceptableContentTypes.contains(HTTPContentType.any) {
      return self
    }

    // if the server did not set the content type then throw a bad server response
    guard let contentTypes = response.contentTypes else {
      throw HTTPError.contentTypeHeaderMissing
    }

    let acceptable = Set(acceptableContentTypes)
    let isDisjoint = contentTypes.isDisjoint(with: acceptable)
    guard isDisjoint else {
      throw HTTPError.invalidContentType
    }

    return self
  }

  /// The set of MIME types this response accepts.
  ///
  /// Returns the value stored in ``HTTPRequest/acceptContentTypes`` or an empty
  /// set when the request (or that property) is unavailable.
  var acceptContentType: Set<HTTPContentType> {
    request.acceptContentTypes ?? [HTTPContentType.any]
  }
}

/// A helper that applies an optional ``Transformer`` to the response body.
///
/// The method will throw if either:
///   * No transformer is supplied – callers are expected to provide one.
///   * The response contains no data (`data == nil`).
///
/// ```swift
/// let decoded: MyModel = try response.transformed(using: JSONDecoder().decode)
/// ```
///
/// - Parameter transformer: A closure that turns raw `Data` into the desired type.
/// - Throws: ``URLError`` when the data is missing or a decoding error occurs.
/// - Returns: The transformed value.
public extension HTTPAnyResponse {
  /// Transforms the underlying data with the supplied transformer.
  ///
  /// This method is intentionally *non‑async* because the transformation itself
  /// operates purely on memory (e.g. JSON decoding).  If you need an async
  /// variant, consider wrapping this call in a `Task` or providing an async
  /// overload that forwards to an asynchronous transformer.
  ///
  /// - Parameter transformer: The closure used to convert raw `Data` into the desired type.
  /// - Returns: The result of applying `transformer` to the response body.
  /// - Throws:
  ///   * ``URLError(.cannotDecodeContentData)`` – if no transformer was provided.
  ///   * ``URLError(.zeroByteResource)`` – if the response contained no data.
  ///   * Any error thrown by `transformer`.
  func transformed<ResultType>(using transformer: Transformer<Data, ResultType>?) throws -> ResultType {
    guard let transformer else {
      throw URLError(.cannotDecodeContentData)
    }

    guard let body = data else {
      throw URLError(.zeroByteResource)
    }

    return try transformer(body)
  }
}
