//
//  HTTPRequestConfigurable.swift
//
//  Created by Waqar Malik on 10/17/23.
//

import Foundation
import HTTPTypes
import HTTPTypesFoundation
import OSLog

#if DEBUG
private let logger = Logger(.init(subsystem: "com.waqarmalik.HTTPRequestable", category: "HTTPRequestConfigurable"))
#else
private let logger = Logger(.disabled)
#endif

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

  /// Path to append to the base URL, optional
  var path: String? { get }

  /// Additional query items to include in the URL
  var queryItems: [URLQueryItem]? { get mutating set }

  /// Additional headers to include in the request
  var headerFields: HTTPFields? { get mutating set }

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
}

/// Default implementation
public extension HTTPRequestConfigurable {
  @inlinable
  var method: HTTPMethod {
    .get
  }

  @inlinable
  var path: String? {
    nil
  }

  @inlinable
  var queryItems: [URLQueryItem]? {
    nil
  }

  @inlinable
  var headerFields: HTTPFields? {
    nil
  }

  @inlinable
  var httpBody: Data? {
    nil
  }

  /// URLConvertible
  var url: URL {
    get throws {
      logger.trace("[IN]: \(#function)")
      var components = environment
      var paths = components.path.components(separatedBy: "/")
      paths.append(contentsOf: path?.components(separatedBy: "/") ?? [])
      paths = paths.filter { !$0.isEmpty }
      if !paths.isEmpty {
        paths.insert("", at: 0)
      }
      components.path = paths.joined(separator: "/")
      var items: [URLQueryItem] = environment.queryItems ?? []
      if let queryItems {
        items.append(contentsOf: queryItems)
      }
      components.queryItems = items.isEmpty ? nil : Array(items)
      guard let url = components.url else {
        throw HTTPError.invalidURL
      }
      return url
    }
  }

  /// HTTPRequestConvertible
  var httpRequest: HTTPRequest {
    get throws {
      try HTTPRequest(method: method, url: url, headerFields: headerFields ?? HTTPFields())
    }
  }

  /// URLRequestConvertible
  var urlRequest: URLRequest {
    get throws {
      logger.trace("[IN]: \(#function)")
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
  /// This property forwards to the static `jsonDecoder` defined on
  /// the type.  It allows concrete request types to provide a reusable
  /// decoder while still exposing an instance‑level transformer that
  /// matches the `HTTPRequestConfigurable` protocol requirement.
  ///
  /// - Returns: The static JSON‑decoder for this request type.
  var responseDataTransformer: Transformer<Data, ResultType> {
    { data in
      try JSONDecoder().decode(ResultType.self, from: data)
    }
  }
}
