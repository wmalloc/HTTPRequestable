//
//  HTTPRequstable.swift
//
//
//  Created by Waqar Malik on 10/17/23.
//

import Foundation
import HTTPTypes

public protocol HTTPRequstable {
  associatedtype ResultType
  
  var scheme: String { get }
  var authority: String { get }
  var method: HTTPRequest.Method { get }
  var path: String { get }
  var headers: HTTPFields { get }

  var transformer: Transformer<Data, ResultType> { get }
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
  
  var headers: HTTPFields {
    HTTPFields([.accept(.json), .defaultUserAgent, .defaultAcceptEncoding, .defaultAcceptLanguage])
  }
  
  func httpRequest(headers: HTTPFields? = nil, queryItems: [URLQueryItem]? = nil) throws -> HTTPRequest {
    var allHeaders = self.headers
    allHeaders.append(contentsOf: headers ?? [:])
    let request = HTTPRequest(method: method, scheme: scheme, authority: authority, path: path, headerFields: allHeaders)
    return request
  }
}

public extension HTTPRequstable where ResultType: Decodable {
  var transformer: Transformer<Data, ResultType> {
    { data in
      try JSONDecoder().decode(ResultType.self, from: data)
    }
  }
}
