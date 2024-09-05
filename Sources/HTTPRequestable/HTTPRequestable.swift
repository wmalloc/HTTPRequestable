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

  /// Override the scheme if needed, defaults to nil
  var scheme: String? { get }

  /// Override the authority if needed, defaults to nil
  var authority: String? { get }

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
  func url() throws -> URL

  /// HTTP Request
  /// - Parameters:
  ///   - fields:     additonal headers, defaults to nil
  ///   - queryItems: additonal query items, defaults to nil
  /// - Returns: HTTPRequest
  func httpRequest() throws -> HTTPRequest

  /// URL Request
  /// - Parameters:
  ///   - fields:     additonal headers, defaults to nil
  ///   - queryItems: additonal query items, defaults to nil
  /// - Returns: URLRequest
  func urlRequest() throws -> URLRequest
}

public extension HTTPRequestable {
  @inlinable
  var scheme: String? { nil }

  @inlinable
  var authority: String? { nil }

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

  func url() throws -> URL {
    logger.trace("[IN]: \(#function)")
    var components = environment
    if let scheme {
      components.scheme = scheme
    }
    if let authority {
      components.host = authority
    }
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

  func httpRequest() throws -> HTTPRequest {
    try HTTPRequest(method: method, url: url(), headerFields: headerFields ?? HTTPFields())
  }

  func urlRequest() throws -> URLRequest {
    logger.trace("[IN]: \(#function)")
    let httpRequest = try httpRequest()
    guard var urlRequest = URLRequest(httpRequest: httpRequest) else {
      throw URLError(.unsupportedURL)
    }
    urlRequest.httpBody = httpBody
    return urlRequest
  }
}
