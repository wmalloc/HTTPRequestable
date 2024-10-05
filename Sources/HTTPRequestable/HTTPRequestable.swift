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
public typealias Transformer<InputType, OutputType> = @Sendable (InputType, HTTPURLResponse?) throws -> OutputType

/// HTTP Request
public typealias URLRequestable = HTTPRequestable

/// URL/HTTP Request builder
public protocol HTTPRequestable: Sendable {
  associatedtype ResultType

  /// URL Components to build the url
  var environment: HTTPEnvironment { get }

  /// Method defaults to .get
  var method: HTTPMethod { get }

  /// Override the path if needed, defaults to nil
  var path: String? { get }

  /// Additional query items if needed, defaults to nil
  var queryItems: [URLQueryItem]? { get }

  /// Additional headers if needed, defaults to nil
  var headerFields: HTTPFields? { get }

  /// Override the body if needed, defaults to nil
  var httpBody: Data? { get }

  /// How to transform the resulting data
  var responseTransformer: Transformer<Data, ResultType> { get }

  /// builds the final url for request
  /// - Parameter queryItems: additonal query items
  /// - Returns: final url
  var url: URL { get throws }

  /// HTTP Request
  /// - Parameters:
  ///   - fields:     additonal headers, defaults to nil
  ///   - queryItems: additonal query items, defaults to nil
  /// - Returns: HTTPRequest
  var httpRequest: HTTPRequest { get throws }

  /// URL Request
  /// - Parameters:
  ///   - fields:     additonal headers, defaults to nil
  ///   - queryItems: additonal query items, defaults to nil
  /// - Returns: URLRequest
  var urlRequest: URLRequest { get throws }
}

public extension HTTPRequestable {
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
        throw URLError(.badURL)
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
        throw URLError(.unsupportedURL)
      }
      urlRequest.httpBody = httpBody
      return urlRequest
    }
  }
}
