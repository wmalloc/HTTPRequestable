//
//  HTTPRequestable.swift
//
//
//  Created by Waqar Malik on 10/17/23.
//

import Foundation
import HTTPTypes
import HTTPTypesFoundation

public typealias HTTPMethod = HTTPRequest.Method
public typealias Transformer<InputType, OutputType> = @Sendable (InputType, HTTPURLResponse?) throws -> OutputType
public typealias HTTPEnvironment = URLComponents
public typealias URLRequestable = HTTPRequestable

public protocol HTTPRequestable: Sendable {
  associatedtype ResultType

  var scheme: String? { get }
  var authority: String? { get }
  var environment: HTTPEnvironment { get }
  var method: HTTPMethod { get }
  var path: String? { get }
  var queryItems: [URLQueryItem]? { get }
  var headerFields: HTTPFields? { get }
  var httpBody: Data? { get }
  var transformer: Transformer<Data, ResultType> { get }

  func url(queryItems: [URLQueryItem]?) throws -> URL
  func httpRequest(fields: HTTPFields?, queryItems: [URLQueryItem]?) throws -> HTTPRequest
  func urlRequest(fields: HTTPFields?, queryItems: [URLQueryItem]?) throws -> URLRequest
}

public extension HTTPRequestable {
  var scheme: String? {
    nil
  }

  var authority: String? {
    nil
  }

  var method: HTTPMethod {
    .get
  }

  var path: String? {
    nil
  }

  var queryItems: [URLQueryItem]? {
    nil
  }

  var headerFields: HTTPFields? {
    HTTPFields.defaultHeaders
  }

  var httpBody: Data? {
    nil
  }

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
