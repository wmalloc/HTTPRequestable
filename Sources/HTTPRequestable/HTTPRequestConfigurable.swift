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
private let logger = Logger(.init(category: "HTTPRequestable"))
#else
private let logger = Logger(.disabled)
#endif

/// Method
public typealias HTTPMethod = HTTPRequest.Method

/// How to transform the resulting data
public typealias Transformer<InputType: Sendable, OutputType: Sendable> = @Sendable (InputType) throws -> OutputType

/// HTTP Request
@available(*, deprecated, renamed: "HTTPRequestConfigurable", message: "Renamed to HTTPRequestConfigurable")
public typealias URLRequestable = HTTPRequestConfigurable

@available(*, deprecated, renamed: "HTTPRequestConfigurable", message: "Renamed to HTTPRequestConfigurable")
public typealias HTTPRequestable = HTTPRequestConfigurable

/// URL/HTTP Request builder protocol
public protocol HTTPRequestConfigurable: URLConvertible, URLRequestConvertible, HTTPRequestConvertible, Sendable {
  associatedtype ResultType: Sendable

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

  /// Transformer to convert raw response data to ResultType
  var responseDataTransformer: Transformer<Data, ResultType>? { get }
}

/// Default imeplementation
public extension HTTPRequestConfigurable {
  @inlinable
  var method: HTTPMethod { .get }

  @inlinable
  var path: String? { nil }

  @inlinable
  var queryItems: [URLQueryItem]? { nil }

  @inlinable
  var headerFields: HTTPFields? { nil }

  @inlinable
  var httpBody: Data? { nil }

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

  var httpRequest: HTTPRequest {
    get throws {
      try HTTPRequest(method: method, url: url, headerFields: headerFields ?? HTTPFields())
    }
  }

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

public extension HTTPRequestConfigurable where ResultType: Decodable {
  /// A convenience transformer that decodes raw JSON `Data` into the conforming `ResultType`.
  ///
  /// - Discussion:
  ///   Use this transformer when your `ResultType` conforms to `Decodable` and the server
  ///   response is JSON. It constructs a new `JSONDecoder` and attempts to decode the given
  ///   `Data` into `ResultType`.
  ///
  /// - Returns: A `Transformer<Data, ResultType>` closure that decodes the input data using `JSONDecoder`.
  ///
  /// - Throws: Rethrows any decoding errors produced by `JSONDecoder.decode(_:from:)`,
  ///   such as `DecodingError.dataCorrupted`, `DecodingError.keyNotFound`,
  ///   `DecodingError.typeMismatch`, or `DecodingError.valueNotFound`.
  ///
  /// - Note:
  ///   - The decoder uses default `JSONDecoder` configuration. If you need custom date,
  ///     key, or data strategies, consider providing your own transformer or extending
  ///     this property to accept a configured `JSONDecoder`.
  ///   - This is only available when `ResultType` conforms to `Decodable`.
  static var jsonDecoder: Transformer<Data, ResultType> {
    { data in
      try JSONDecoder().decode(ResultType.self, from: data)
    }
  }
}
