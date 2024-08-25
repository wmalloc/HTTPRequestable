//
//  HTTPRequestable.swift
//
//
//  Created by Waqar Malik on 10/17/23.
//

import Foundation
import HTTPTypes
import HTTPTypesFoundation

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
  var environment: HTTPEnvironment { get set }

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
  func url(queryItems: [URLQueryItem]?) throws -> URL

  /// HTTP Request
  /// - Parameters:
  ///   - fields: additonal headers, defaults to nil
  ///   - queryItems: additonal query items, defaults to nil
  /// - Returns: HTTPRequest
  func httpRequest(fields: HTTPFields?, queryItems: [URLQueryItem]?) throws -> HTTPRequest

  /// URL Request
  /// - Parameters:
  ///   - fields: additonal headers, defaults to nil
  ///   - queryItems: additonal query items, defaults to nil
  /// - Returns: URLRequest
  func urlRequest(fields: HTTPFields?, queryItems: [URLQueryItem]?) throws -> URLRequest
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

  var headerFields: HTTPFields? { HTTPFields.defaultHeaders }

  @inlinable
  var httpBody: Data? { nil }

  func url(queryItems: [URLQueryItem]? = nil) throws -> URL {
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
    items.append(contentsOf: self.queryItems ?? [])
    items.append(contentsOf: queryItems ?? [])
    components.queryItems = items.isEmpty ? nil : Array(items)
    guard let url = components.url else {
      throw URLError(.badURL)
    }
    return url
  }

  func httpRequest(fields: HTTPFields? = nil, queryItems: [URLQueryItem]? = nil) throws -> HTTPRequest {
    var allHeaderFields = headerFields ?? HTTPFields()
    allHeaderFields.append(contentsOf: fields ?? [:])
    return try HTTPRequest(method: method, url: url(queryItems: queryItems), headerFields: allHeaderFields)
  }

  func urlRequest(fields: HTTPFields? = nil, queryItems: [URLQueryItem]? = nil) throws -> URLRequest {
    let httpRequest = try httpRequest(fields: fields, queryItems: queryItems)
    guard var urlRequest = URLRequest(httpRequest: httpRequest) else {
      throw URLError(.unsupportedURL)
    }
    urlRequest.httpBody = httpBody
    return urlRequest
  }
}
