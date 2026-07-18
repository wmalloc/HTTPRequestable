//
//  APIRequest.swift
//
//  Created by Waqar Malik on 2026-06-02.
//

import Foundation
import HTTPTypes
import HTTPTypesFoundation

/// A reusable, generic implementation of ``HTTPRequestConfigurable``.
///
/// `APIRequest` lets callers describe a one-off HTTP request without
/// having to declare a dedicated type for every endpoint. Provide an
/// ``HTTPEnvironment``, method, path, optional headers, query items, body, and
/// a transformer that converts the raw `Data` response into `ResultType`.
///
/// ## Example
///
/// ```swift
/// struct Story: Decodable { let id: Int; let title: String }
///
/// let request = APIRequest<Story>(
///   environment: environment,
///   path: "/item/8863.json"
/// )
/// let story = try await api.object(for: request)
/// ```
///
/// For non-`Decodable` result types, supply a custom `responseDataTransformer`:
///
/// ```swift
/// let xmlRequest = APIRequest<XMLDocument>(
///   environment: environment,
///   path: "/feed.xml",
///   responseDataTransformer: { try XMLDocument(data: $0) }
/// )
/// ```
public struct APIRequest<ResultType>: HTTPRequestConfigurable {
  public var environment: HTTPEnvironment
  public var method: HTTPMethod
  public var path: String?
  public var queryItems: [URLQueryItem]?
  public var headerFields: HTTPFields?
  public var httpBody: Data?
  public var responseDataTransformer: Transformer<Data, ResultType>

  /// Creates a generic request with a caller-supplied response transformer.
  ///
  /// - Parameters:
  ///   - environment: The ``HTTPEnvironment`` providing the base URL components.
  ///   - method: The HTTP method. Defaults to `.get`.
  ///   - path: An optional path appended to `environment.path`.
  ///   - queryItems: Additional query items merged with `environment.queryItems`.
  ///   - headerFields: Headers applied to the resulting request.
  ///   - httpBody: Body data attached to the resulting `URLRequest`.
  ///   - responseDataTransformer: Closure that converts response `Data` into `ResultType`.
  public init(_ environment: HTTPEnvironment, method: HTTPMethod = .get, path: String? = nil,
              queryItems: [URLQueryItem]? = nil, headerFields: HTTPFields? = nil, httpBody: Data? = nil,
              responseDataTransformer: @escaping Transformer<Data, ResultType>) {
    self.environment = environment
    self.method = method
    self.path = path
    self.queryItems = queryItems
    self.headerFields = headerFields
    self.httpBody = httpBody
    self.responseDataTransformer = responseDataTransformer
  }
}

public extension APIRequest where ResultType == Data {
  /// Creates a request that returns the raw response bytes as `Data`.
  ///
  /// - Parameters:
  ///   - environment: The ``HTTPEnvironment`` providing the base URL components.
  ///   - method: The HTTP method. Defaults to `.get`.
  ///   - path: An optional path appended to `environment.path`.
  ///   - queryItems: Additional query items merged with `environment.queryItems`.
  ///   - headerFields: Headers applied to the resulting request.
  ///   - httpBody: Body data attached to the resulting `URLRequest`.
  init(_ environment: HTTPEnvironment, method: HTTPMethod = .get, path: String? = nil,
       queryItems: [URLQueryItem]? = nil, headerFields: HTTPFields? = nil, httpBody: Data? = nil) {
    self.init(environment, method: method, path: path,
      queryItems: queryItems, headerFields: headerFields, httpBody: httpBody,
      responseDataTransformer: { $0 } )
  }
}

public extension APIRequest where ResultType: Decodable {
  /// Creates a request whose response is decoded as `ResultType` using `JSONDecoder`.
  ///
  /// - Parameters:
  ///   - environment: The ``HTTPEnvironment`` providing the base URL components.
  ///   - method: The HTTP method. Defaults to `.get`.
  ///   - path: An optional path appended to `environment.path`.
  ///   - queryItems: Additional query items merged with `environment.queryItems`.
  ///   - headerFields: Headers applied to the resulting request.
  ///   - httpBody: Body data attached to the resulting `URLRequest`.
  init(_ environment: HTTPEnvironment, method: HTTPMethod = .get, path: String? = nil,
       queryItems: [URLQueryItem]? = nil, headerFields: HTTPFields? = nil, httpBody: Data? = nil) {
    self.init(environment, method: method, path: path,
      queryItems: queryItems, headerFields: headerFields, httpBody: httpBody,
      responseDataTransformer: { try JSONDecoder().decode(ResultType.self, from: $0) })
  }
}
