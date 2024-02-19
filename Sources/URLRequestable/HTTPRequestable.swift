//
//  HTTPRequstable.swift
//
//
//  Created by Waqar Malik on 10/17/23.
//

import Foundation
import HTTPTypes
import HTTPTypesFoundation

public typealias HTTPMethod = HTTPRequest.Method

public protocol HTTPRequestable {
  associatedtype ResultType

  var scheme: String { get }
  var authority: String { get }
  var method: HTTPMethod { get }
  var path: String { get }
  var queryItems: Array<URLQueryItem>? { get }
  var headers: HTTPFields { get }
  var transformer: Transformer<Data, ResultType> { get }

  func url(queryItems: Array<URLQueryItem>?) throws -> URL
  func httpRequest(headers: HTTPFields?, queryItems: Array<URLQueryItem>?) throws -> HTTPRequest
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

  var queryItems: Array<URLQueryItem>? {
    nil
  }

  var headers: HTTPFields {
    HTTPFields([.accept(.json), .defaultUserAgent, .defaultAcceptEncoding, .defaultAcceptLanguage])
  }

  func url(queryItems: Array<URLQueryItem>? = nil) throws -> URL {
    var components = URLComponents()
    components.scheme = scheme
    components.host = authority
    components.path = path
    var items: Array<URLQueryItem> = self.queryItems ?? []
    items.append(contentsOf: queryItems ?? [])
    components.queryItems = items.isEmpty ? nil : Array(items)
    guard let url = components.url else {
      throw URLError(.badURL)
    }
    return url
  }

  func httpRequest(headers: HTTPFields? = nil, queryItems: Array<URLQueryItem>? = nil) throws -> HTTPRequest {
    var allHeaders = self.headers
    allHeaders.append(contentsOf: headers ?? [:])
    let request = try HTTPRequest(method: method, url: url(queryItems: queryItems), headerFields: allHeaders)
    return request
  }
}

public extension HTTPRequestable where ResultType: Decodable {
  var transformer: Transformer<Data, ResultType> {
    { data in
      try JSONDecoder().decode(ResultType.self, from: data)
    }
  }
}
