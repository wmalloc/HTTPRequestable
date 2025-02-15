//
//  HTTPEnvironment.swift
//
//  Created by Waqar Malik on 4/28/23.
//

import Foundation

/// Represents a set of properties for an HTTP environment, which includes URL components like scheme, host, path, query items, etc.
public typealias HTTPEnvironment = URLComponents

public extension HTTPEnvironment {
  /// Initializes an `HTTPEnvironment` with the given scheme, authority (host), and optional path.
  ///
  /// - Parameters:
  ///   - scheme: The scheme of the URL (e.g., "https").
  ///   - authority: The authority part of the URL which includes the host.
  ///   - path: The path component of the URL (optional).
  init(scheme: String, authority: String, path: String = "") {
    self.init()
    self.scheme = scheme
    self.host = authority
    self.path = path
  }

  @discardableResult
  func setAuthority(_ authority: String) -> Self {
    setHost(authority)
  }

  @discardableResult
  func setScheme(_ scheme: String) -> Self {
    var components = self
    components.scheme = scheme
    return components
  }

  @discardableResult
  func setHost(_ host: String?) -> Self {
    var components = self
    components.host = host
    return components
  }

  @discardableResult
  func setPath(_ path: String) -> Self {
    var components = self
    components.path = path
    return components
  }

  @discardableResult
  func setQueryItems(_ queryItems: [URLQueryItem]) -> Self {
    var components = self
    components.queryItems = queryItems.isEmpty ? nil : queryItems
    return components
  }

  @discardableResult
  func setQueryItems(_ queryItems: [String: String]) -> Self {
    let queryItems = queryItems.map { URLQueryItem(name: $0, value: $1) }
    return setQueryItems(queryItems)
  }

  @discardableResult
  func setQueryItems(_ queryItems: [String: Any]) -> Self {
    let queryItems = queryItems.map { URLQueryItem(name: $0, value: "\($1)") }
    return setQueryItems(queryItems)
  }

  @discardableResult
  func appendQueryItems(_ newQueryItems: [URLQueryItem]) -> Self {
    var existingQueryItems = queryItems ?? []
    existingQueryItems.append(contentsOf: newQueryItems)
    return setQueryItems(existingQueryItems)
  }

  @discardableResult
  func appendQueryItems(_ parameters: [String: String]) -> Self {
    let newQueryItems = parameters.map { (key: String, value: String) -> URLQueryItem in
      URLQueryItem(name: key, value: value)
    }
    return appendQueryItems(newQueryItems)
  }

  @discardableResult
  func appendQueryItems(_ parameters: [String: Any]) -> Self {
    let newQueryItems = parameters.map { (key: String, value: Any) -> URLQueryItem in
      URLQueryItem(name: key, value: "\(value)")
    }
    return appendQueryItems(newQueryItems)
  }

  @discardableResult
  func setFragment(_ fragment: String?) -> Self {
    var components = self
    components.fragment = fragment
    return components
  }

  @discardableResult
  func setUser(_ user: String?) -> Self {
    var components = self
    components.user = user
    return components
  }

  @discardableResult
  func setPassword(_ password: String?) -> Self {
    var components = self
    components.password = password
    return components
  }

  @discardableResult
  func setQuery(_ query: String?) -> Self {
    var components = self
    components.query = query
    return components
  }

  @discardableResult
  func setPercentEncodedQuery(_ percentEncodedQuery: String?) -> Self {
    var components = self
    components.percentEncodedQuery = percentEncodedQuery
    return components
  }

  @discardableResult
  func setPercentEncodedUser(_ percentEncodedUser: String?) -> Self {
    var components = self
    components.percentEncodedUser = percentEncodedUser
    return components
  }

  @discardableResult
  func setPercentEncodedHost(_ percentEncodedHost: String?) -> Self {
    var components = self
    components.percentEncodedHost = percentEncodedHost
    return components
  }

  @discardableResult
  func setPercentEncodedPassword(_ percentEncodedPassword: String?) -> Self {
    var components = self
    components.percentEncodedPassword = percentEncodedPassword
    return components
  }

  @discardableResult
  func setPercentEncodedPath(_ percentEncodedPath: String) -> Self {
    var components = self
    components.percentEncodedPath = percentEncodedPath
    return components
  }

  @discardableResult
  func setPercentEncodedFragment(_ percentEncodedFragment: String?) -> Self {
    var components = self
    components.percentEncodedFragment = percentEncodedFragment
    return components
  }

  @discardableResult
  func setPercentEncodedQueryItems(_ percentEncodedQueryItems: [URLQueryItem]) -> Self {
    var components = self
    components.percentEncodedQueryItems = percentEncodedQueryItems.isEmpty ? nil : percentEncodedQueryItems
    return components
  }

  @discardableResult
  func appendPercentEncodedQueryItems(_ percentEncodedQueryItems: [URLQueryItem]) -> Self {
    var existingQueryItems = self.percentEncodedQueryItems ?? []
    existingQueryItems.append(contentsOf: percentEncodedQueryItems)
    return setPercentEncodedQueryItems(existingQueryItems)
  }
}
