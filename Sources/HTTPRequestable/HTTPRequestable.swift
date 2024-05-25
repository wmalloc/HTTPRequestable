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
public typealias Transformer<InputType, OutputType> = @Sendable (InputType, HTTPURLResponse) throws -> OutputType

public protocol HTTPRequestable: Sendable {
  associatedtype ResultType

  var scheme: String { get }
  var authority: String { get }
  var method: HTTPMethod { get }
  var path: String { get }
  var queryItems: [URLQueryItem]? { get }
  var headerFields: HTTPFields? { get }
  var httpBody: Data? { get }
  var transformer: Transformer<Data, ResultType> { get }

  func url(queryItems: [URLQueryItem]?) throws -> URL
  func httpRequest(fields: HTTPFields?, queryItems: [URLQueryItem]?) throws -> HTTPRequest
  func urlRequest(fields: HTTPFields?, queryItems: [URLQueryItem]?) throws -> URLRequest
}

public extension HTTPRequestable {
  var scheme: String {
    "https"
  }

  var method: HTTPMethod {
    .get
  }

  var path: String {
    ""
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
    var components = URLComponents()
    components.scheme = scheme
    components.host = authority
    components.path = path
    var items: [URLQueryItem] = self.queryItems ?? []
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
    guard let urlRequest = URLRequest(httpRequest: httpRequest) else {
      throw URLError(.unsupportedURL)
    }
    return urlRequest
      .setHttpBody(httpBody)
  }
}
