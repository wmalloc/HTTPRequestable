//
//  HTTPRequestable.swift
//
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
@available(*, deprecated, renamed: "HTTPRequestConvertible", message: "Renamed to HTTPRequestConvertible")
public typealias URLRequestable = HTTPRequestConvertible

@available(*, deprecated, renamed: "HTTPRequestConvertible", message: "Renamed to HTTPRequestConvertible")
public typealias HTTPRequestable = HTTPRequestConvertible

/// URL/HTTP Request builder protocol
public protocol HTTPRequestConvertible: Sendable {
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

  /// Constructs the final URL with query items
  /// - Parameter queryItems: additonal query items
  /// - Returns: final url
  var url: URL { get throws }

  /// Constructs the HTTPRequest object
  /// - Parameters:
  ///   - fields:     additonal headers, defaults to nil
  ///   - queryItems: additonal query items, defaults to nil
  /// - Returns: HTTPRequest
  var httpRequest: HTTPRequest { get throws }

  /// Constructs the URLRequest object
  /// - Parameters:
  ///   - fields:     additonal headers, defaults to nil
  ///   - queryItems: additonal query items, defaults to nil
  /// - Returns: URLRequest
  var urlRequest: URLRequest { get throws }
}

/// Default imeplementation
public extension HTTPRequestConvertible {
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

public extension HTTPRequestConvertible where ResultType: Decodable {
  static var jsonDecoder: Transformer<Data, ResultType> {
    { data in
      try JSONDecoder().decode(ResultType.self, from: data)
    }
  }
}
