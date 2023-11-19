//
//  HTTPRequstable.swift
//
//
//  Created by Waqar Malik on 10/17/23.
//

import Foundation
import HTTPTypes
import HTTPTypesFoundation

public protocol HTTPRequstable {
  associatedtype ResultType
  
  var scheme: String { get }
  var authority: String { get }
  var method: HTTPRequest.Method { get }
  var path: String { get }
  var queryItems: Set<URLQueryItem>? { get }
  var headers: HTTPFields { get }
  var transformer: Transformer<Data, ResultType> { get }
  
  func url(queryItems: Set<URLQueryItem>?) throws -> URL
  func httpRequest(headers: HTTPFields?, queryItems: [URLQueryItem]?) throws -> HTTPRequest
}

public extension HTTPRequstable {
  var scheme: String {
    "https"
  }
  
  var method: URLRequest.Method {
    .get
  }

  var path: String {
    ""
  }
  
  var queryItems: Set<URLQueryItem>? {
    nil
  }
  
  var headers: HTTPFields {
    HTTPFields([.accept(.json), .defaultUserAgent, .defaultAcceptEncoding, .defaultAcceptLanguage])
  }
  
  func httpRequest(headers: HTTPFields? = nil, queryItems: [URLQueryItem]? = nil) throws -> HTTPRequest {
    var allHeaders = self.headers
    allHeaders.append(contentsOf: headers ?? [:])
    let request = HTTPRequest(method: method, url: try url(queryItems: queryItems), headerFields: allHeaders)
    return request
  }
  
  func url(queryItems: [URLQueryItem]? = nil) throws -> URL {
    var components = URLComponents()
    components.scheme = scheme
    components.host = authority
    components.path = path
    var items: Set<URLQueryItem> = self.queryItems ?? []
    items.formUnion(queryItems ?? [])
    components.queryItems = items.isEmpty ? nil : Array(items)
    guard let url = components.url else {
      throw URLError(.badURL)
    }
    return url
  }
}

public extension HTTPRequstable where ResultType: Decodable {
  var transformer: Transformer<Data, ResultType> {
    { data in
      try JSONDecoder().decode(ResultType.self, from: data)
    }
  }
}
