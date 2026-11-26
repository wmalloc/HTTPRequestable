//
//  HTTPRequestConfigurable.swift
//
//  Created by Waqar Malik on 10/17/23.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import HTTPTypes
import HTTPTypesFoundation

/// Method
public typealias HTTPMethod = HTTPRequest.Method

/// Synchronous transformer for converting data from one type to another.
///
/// This typealias defines a closure that takes an input value and returns
/// an output value, potentially throwing an error during the transformation.
///
/// ## Example
///
/// ```swift
/// let jsonTransformer: Transformer<Data, User> = { data in
///     try JSONDecoder().decode(User.self, from: data)
/// }
/// ```
public typealias Transformer<InputType, OutputType> = (InputType) throws -> OutputType

/// URL/HTTP Request builder protocol
public protocol HTTPRequestConfigurable: URLConvertible, URLRequestConvertible, HTTPRequestConvertible {
  associatedtype ResultType

  /// Environment containing base URL and other configuration settings
  var environment: HTTPEnvironment { get }

  /// Method for the request, default is GET
  var method: HTTPMethod { get }

  /// Path to append to the base URL
  ///
  /// The path is split on `/` into segments; empty segments are removed. Use ``pathComponents`` instead
  /// when a segment comes from a value that may itself contain `/`, such as an ID or a file name.
  var path: String { get }

  /// The path segments to append to the environment's path, each percent-encoded on its own.
  ///
  /// A `/` inside a segment is sent as `%2F`, so a value cannot add segments of its own. Empty segments
  /// are removed. The default implementation splits ``path`` on `/`.
  ///
  /// ```swift
  /// var pathComponents: [String] { ["files", fileName] }  // "a/b.txt" → /files/a%2Fb.txt
  /// ```
  ///
  /// - Note: A segment of `.` or `..` makes ``url`` throw, because servers resolve them and the request
  ///   could reach a different path.
  var pathComponents: [String] { get }

  /// Additional query items to include in the URL
  var queryItems: [URLQueryItem] { get mutating set }

  /// Additional headers to include in the request
  var headerFields: HTTPFields { get mutating set }

  /// Body data for the request, optional
  var httpBody: Data? { get }

  /// Synchronous transformer to convert raw response data to ResultType.
  ///
  /// This property provides a closure that transforms the HTTP response data
  /// into the expected result type. For most use cases, use the default
  /// implementations provided for common types like `Void`, `Data`, `String`,
  /// and `Decodable`.
  ///
  /// - Returns: A closure that converts `Data` to `ResultType`, or `nil` if
  ///   no transformation is needed.
  var responseDataTransformer: Transformer<Data, ResultType> { get }

  /// Checks a response before ``responseDataTransformer`` decodes it in `object(for:delegate:)`.
  ///
  /// The default accepts only successful (`2xx`) statuses, so an error page is never decoded as a
  /// result. Implement it to accept other statuses, to also check the content type with
  /// `HTTPClientResponse.validate()`, or to throw an error of your own built from the response body.
  ///
  /// ```swift
  /// func validateResponse(_ response: HTTPClientResponse) throws {
  ///   guard response.response.status.kind == .successful else {
  ///     throw try JSONDecoder().decode(APIError.self, from: response.responseData)
  ///   }
  /// }
  /// ```
  ///
  /// - Parameter response: The response, with its status, headers and body.
  /// - Throws: An error to stop the response from being decoded. The default throws
  ///   `HTTPError.unacceptableStatusCode` for a status outside `2xx`.
  func validateResponse(_ response: HTTPClientResponse) throws
}

/// Default implementation
public extension HTTPRequestConfigurable {
  /// Accepts only successful (`2xx`) statuses.
  ///
  /// - Throws: `HTTPError.unacceptableStatusCode` for a status outside `2xx`.
  func validateResponse(_ response: HTTPClientResponse) throws {
    try response.validateStatus()
  }

  @inlinable
  var method: HTTPMethod {
    .get
  }

  @inlinable
  var path: String {
    ""
  }

  @inlinable
  var httpBody: Data? {
    nil
  }

  var pathComponents: [String] {
    path.split(separator: "/").map(String.init)
  }

  /// The request URL: the environment with ``pathComponents`` and ``queryItems`` appended.
  ///
  /// - The environment's path is kept as it is percent-encoded, and each of ``pathComponents`` is
  ///   percent-encoded on its own and appended. Empty segments are removed and the result has a single
  ///   leading `/`, so a trailing `/` is not kept.
  /// - The environment's query is kept as it is percent-encoded, and ``queryItems`` are appended after it,
  ///   with `&`, `=`, `;` and `+` in names and values percent-encoded.
  /// - Any user name or password on the environment is removed. `HTTPRequest` never sends them, so
  ///   keeping them would only put credentials where the URL gets logged.
  ///
  /// - Throws: `HTTPError.invalidURL` when the environment has no scheme or no host, when a path segment is
  ///   `.` or `..` (also percent-encoded), or when no URL can be formed.
  var url: URL {
    get throws {
      var components = environment
      guard components.scheme?.isEmpty == false, components.host?.isEmpty == false else {
        throw HTTPError.invalidURL
      }

      let segments = components.percentEncodedPath.split(separator: "/").map(String.init)
        + pathComponents.filter { !$0.isEmpty }.map(URLEncoding.pathSegment)
      guard !segments.contains(where: URLEncoding.isDotSegment) else {
        throw HTTPError.invalidURL
      }
      components.percentEncodedPath = segments.isEmpty ? "" : "/" + segments.joined(separator: "/")
      components.percentEncodedQuery = URLEncoding.joinedQuery(environment.percentEncodedQuery, URLEncoding.query(queryItems))
      components.user = nil
      components.password = nil

      guard let url = components.url, URLEncoding.isRequestable(url) else {
        throw HTTPError.invalidURL
      }
      return url
    }
  }

  /// HTTPRequestConvertible
  ///
  /// - Throws: `HTTPError.invalidURL` when ``url`` throws.
  var httpRequest: HTTPRequest {
    get throws {
      try HTTPRequest(method: method, url: url, headerFields: headerFields)
    }
  }

  /// URLRequestConvertible
  var urlRequest: URLRequest {
    get throws {
      let httpRequest = try httpRequest
      guard var urlRequest = URLRequest(httpRequest: httpRequest) else {
        throw HTTPError.cannotCreateURLRequest
      }
      urlRequest.httpBody = httpBody
      return urlRequest
    }
  }
}

/// Transformer when there is nothing to be returned
public extension HTTPRequestConfigurable where ResultType == Void {
  var responseDataTransformer: Transformer<Data, ResultType> {
    { _ in () }
  }
}

public extension HTTPRequestConfigurable where ResultType == Data {
  /// Identity transformer for requests whose result type is `Data`.
  ///
  /// Many requests return raw binary data that the caller wishes to
  /// consume directly.  This extension supplies a default `responseDataTransformer`
  /// that simply forwards the data unchanged, so no custom decoding is
  /// required.  Conforming types can override this property if they need
  /// to perform additional processing (e.g. validation or logging).
  ///
  /// The transformer has the signature `Transformer<Data, ResultType>`
  /// and is implemented as `{ $0 }`, i.e. “return the input”.
  ///
  /// - Returns: A closure that returns its argument unchanged.
  var responseDataTransformer: Transformer<Data, ResultType> {
    { $0 }
  }
}

public extension HTTPRequestConfigurable where ResultType == String {
  /// Default UTF-8 string transformer for requests whose result type is `String`.
  ///
  /// This extension provides a default `responseDataTransformer` that converts
  /// the response data to a UTF-8 encoded string. This is useful for APIs that
  /// return plain text, HTML, XML, or other text-based formats.
  ///
  /// ## Example
  ///
  /// ```swift
  /// struct TextAPIRequest: HTTPRequestConfigurable {
  ///     typealias ResultType = String
  ///     var environment: HTTPEnvironment
  ///     var path: String?
  ///     // responseDataTransformer is automatically provided
  /// }
  ///
  /// let request = TextAPIRequest(environment: env, path: "/text")
  /// let text = try await session.data(for: request)
  /// ```
  ///
  /// - Returns: A closure that converts `Data` to a UTF-8 `String`.
  /// - Throws: `URLError(.cannotDecodeContentData)` if the data is not valid UTF-8.
  var responseDataTransformer: Transformer<Data, ResultType> {
    { data in
      guard let string = String(data: data, encoding: .utf8) else {
        throw URLError(.cannotDecodeContentData)
      }
      return string
    }
  }
}

public extension HTTPRequestConfigurable where ResultType: Decodable {
  /// Default JSON decoder for requests whose result type is `Decodable`.
  ///
  /// This default uses a new `JSONDecoder()` instance with its default configuration
  /// to decode the response data into `ResultType`. Conforming types may override
  /// `responseDataTransformer` to supply a customized decoder or decoding behavior
  /// (for example, different date strategies or key decoding).
  ///
  /// - Returns: A closure that decodes `Data` into `ResultType` using `JSONDecoder()`.
  /// - Throws: `URLError(.zeroByteResource)` when the body is empty, which no JSON value can be, or a
  ///   `DecodingError`.
  var responseDataTransformer: Transformer<Data, ResultType> {
    { data in
      guard !data.isEmpty else {
        throw URLError(.zeroByteResource)
      }
      return try JSONDecoder().decode(ResultType.self, from: data)
    }
  }
}
