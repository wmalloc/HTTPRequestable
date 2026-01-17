//
//  HTTPEnvironment.swift
//
//  Created by Waqar Malik on 4/28/23.
//

import Foundation

/// A type alias for :class:`URLComponents` that represents a full HTTP URL.
///
/// The alias exists so the rest of the codebase can refer to an “environment” instead
/// of a generic URL‑components struct, making intent clearer when building request URLs.
public typealias HTTPEnvironment = URLComponents

// MARK: - Initializers

public extension HTTPEnvironment {
  /// Creates an ``HTTPEnvironment`` with a host, scheme and optional path.
  ///
  /// The initializer sets the `scheme`, `host` and optionally the `path`.
  /// If *path* is omitted, it defaults to an empty string.
  ///
  /// - Parameters:
  ///   - authority: The host component of the URL (e.g. `"api.example.com"`).
  ///   - scheme: The URL scheme, defaulting to `https`.
  ///   - path: Optional path component; if omitted the path is set to an empty string.
  init(authority: String, scheme: String = "https", path: String? = nil) {
    self.init()
    self.scheme = scheme
    self.host = authority
    self.path = path ?? ""
  }

  // MARK: - Host / Authority

  /// Sets the host (authority) of the URL and returns a new instance.
  ///
  /// The original ``HTTPEnvironment`` is immutable; the returned value
  /// contains the updated host.
  ///
  /// - Parameter authority: The new host string (e.g. `"api.example.com"`).
  /// - Returns: A copy of the current environment with the host updated.
  @discardableResult
  func setAuthority(_ authority: String) -> Self {
    setHost(authority)
  }

  /// Sets the scheme of the URL and returns a new instance.
  ///
  /// The original environment is left untouched; this method performs
  /// a copy‑modify pattern that is common in value types.
  ///
  /// - Parameter scheme: The new URL scheme (e.g. `"http"` or `"https"`).
  /// - Returns: A copy of the current environment with the scheme updated.
  @discardableResult
  func setScheme(_ scheme: String) -> Self {
    var components = self
    components.scheme = scheme
    return components
  }

  /// Sets the host component and returns a new instance.
  ///
  /// - Parameter host: The new host string or `nil` to clear the component.
  /// - Returns: A copy of the current environment with the host updated.
  @discardableResult
  func setHost(_ host: String?) -> Self {
    var components = self
    components.host = host
    return components
  }

  // MARK: - Path

  /// Sets the path component of the URL and returns a new instance.
  ///
  /// - Parameter path: The new path string (e.g. `"/v1/users"`).
  /// - Returns: A copy of the current environment with the path updated.
  @discardableResult
  func setPath(_ path: String) -> Self {
    var components = self
    components.path = path
    return components
  }

  // MARK: - Query Items

  /// Replaces the query items with a new array and returns a new instance.
  ///
  /// If *queryItems* is empty, the `queryItems` property will be set to `nil`
  /// (i.e. no query component in the URL).
  ///
  /// - Parameter queryItems: An array of :class:`URLQueryItem`.
  /// - Returns: A copy of the current environment with the query items updated.
  @discardableResult
  func setQueryItems(_ queryItems: [URLQueryItem]) -> Self {
    var components = self
    components.queryItems = queryItems.isEmpty ? nil : queryItems
    return components
  }

  /// Convenience wrapper that accepts a dictionary of `String:String` pairs.
  ///
  /// The dictionary keys become query‑item names and the values become
  /// their string representations.
  ///
  /// - Parameter queryItems: Dictionary of key‑value pairs.
  /// - Returns: A copy of the current environment with the query items updated.
  @discardableResult
  func setQueryItems(_ queryItems: [String: String]) -> Self {
    let items = queryItems.map { URLQueryItem(name: $0, value: $1) }
    return setQueryItems(items)
  }

  /// Convenience wrapper that accepts a dictionary of `String:Any` pairs.
  ///
  /// Values are converted to strings via ``String(describing:)``.
  ///
  /// - Parameter queryItems: Dictionary of key‑value pairs.
  /// - Returns: A copy of the current environment with the query items updated.
  @discardableResult
  func setQueryItems(_ queryItems: [String: Any]) -> Self {
    let items = queryItems.map { URLQueryItem(name: $0, value: "\($1)") }
    return setQueryItems(items)
  }

  /// Appends new query items to the existing ones.
  ///
  /// Existing items are preserved; if no items exist, the new ones become the sole query.
  ///
  /// - Parameter newQueryItems: An array of :class:`URLQueryItem` to append.
  /// - Returns: A copy of the current environment with the query items appended.
  @discardableResult
  func appendQueryItems(_ newQueryItems: [URLQueryItem]) -> Self {
    var existing = queryItems ?? []
    existing.append(contentsOf: newQueryItems)
    return setQueryItems(existing)
  }

  /// Convenience wrapper that accepts a dictionary of `String:String` pairs.
  ///
  /// The dictionary is converted to an array of ``URLQueryItem`` and appended.
  ///
  /// - Parameter parameters: Dictionary of key‑value pairs to append.
  /// - Returns: A copy of the current environment with the query items appended.
  @discardableResult
  func appendQueryItems(_ parameters: [String: String]) -> Self {
    let items = parameters.map { URLQueryItem(name: $0, value: $1) }
    return appendQueryItems(items)
  }

  /// Convenience wrapper that accepts a dictionary of `String:Any` pairs.
  ///
  /// Values are stringified via ``String(describing:)`` before appending.
  ///
  /// - Parameter parameters: Dictionary of key‑value pairs to append.
  /// - Returns: A copy of the current environment with the query items appended.
  @discardableResult
  func appendQueryItems(_ parameters: [String: Any]) -> Self {
    let items = parameters.map { URLQueryItem(name: $0, value: "\($1)") }
    return appendQueryItems(items)
  }

  // MARK: - Fragment

  /// Sets the fragment component and returns a new instance.
  ///
  /// - Parameter fragment: The new fragment string or `nil` to clear it.
  /// - Returns: A copy of the current environment with the fragment updated.
  @discardableResult
  func setFragment(_ fragment: String?) -> Self {
    var components = self
    components.fragment = fragment
    return components
  }

  // MARK: - User / Password

  /// Sets the user component and returns a new instance.
  ///
  /// - Parameter user: The new user string or `nil` to clear it.
  /// - Returns: A copy of the current environment with the user updated.
  @discardableResult
  func setUser(_ user: String?) -> Self {
    var components = self
    components.user = user
    return components
  }

  /// Sets the password component and returns a new instance.
  ///
  /// - Parameter password: The new password string or `nil` to clear it.
  /// - Returns: A copy of the current environment with the password updated.
  @discardableResult
  func setPassword(_ password: String?) -> Self {
    var components = self
    components.password = password
    return components
  }

  // MARK: - Query / Percent‑Encoded Variants

  /// Sets the raw query string and returns a new instance.
  ///
  /// - Parameter query: The un‑escaped query string or `nil` to clear it.
  /// - Returns: A copy of the current environment with the query updated.
  @discardableResult
  func setQuery(_ query: String?) -> Self {
    var components = self
    components.query = query
    return components
  }

  /// Sets the percent‑encoded query string and returns a new instance.
  ///
  /// - Parameter percentEncodedQuery: The percent‑encoded query string or `nil`.
  /// - Returns: A copy of the current environment with the percent‑encoded query updated.
  @discardableResult
  func setPercentEncodedQuery(_ percentEncodedQuery: String?) -> Self {
    var components = self
    components.percentEncodedQuery = percentEncodedQuery
    return components
  }

  /// Sets the percent‑encoded user component.
  ///
  /// - Parameter percentEncodedUser: The percent‑encoded username or `nil`.
  /// - Returns: A copy of the current environment with the user updated.
  @discardableResult
  func setPercentEncodedUser(_ percentEncodedUser: String?) -> Self {
    var components = self
    components.percentEncodedUser = percentEncodedUser
    return components
  }

  /// Sets the percent‑encoded host component.
  ///
  /// - Parameter percentEncodedHost: The percent‑encoded host string or `nil`.
  /// - Returns: A copy of the current environment with the host updated.
  @discardableResult
  func setPercentEncodedHost(_ percentEncodedHost: String?) -> Self {
    var components = self
    components.percentEncodedHost = percentEncodedHost
    return components
  }

  /// Sets the percent‑encoded password component.
  ///
  /// - Parameter percentEncodedPassword: The percent‑encoded password string or `nil`.
  /// - Returns: A copy of the current environment with the password updated.
  @discardableResult
  func setPercentEncodedPassword(_ percentEncodedPassword: String?) -> Self {
    var components = self
    components.percentEncodedPassword = percentEncodedPassword
    return components
  }

  /// Sets the percent‑encoded path component.
  ///
  /// - Parameter percentEncodedPath: The percent‑encoded path string (must not be empty).
  /// - Returns: A copy of the current environment with the path updated.
  @discardableResult
  func setPercentEncodedPath(_ percentEncodedPath: String) -> Self {
    var components = self
    components.percentEncodedPath = percentEncodedPath
    return components
  }

  /// Sets the percent‑encoded fragment component.
  ///
  /// - Parameter percentEncodedFragment: The percent‑encoded fragment string or `nil`.
  /// - Returns: A copy of the current environment with the fragment updated.
  @discardableResult
  func setPercentEncodedFragment(_ percentEncodedFragment: String?) -> Self {
    var components = self
    components.percentEncodedFragment = percentEncodedFragment
    return components
  }

  /// Replaces the percent‑encoded query items with a new array.
  ///
  /// If *percentEncodedQueryItems* is empty, the property will be set to `nil`.
  ///
  /// - Parameter percentEncodedQueryItems: Array of ``URLQueryItem``.
  /// - Returns: A copy of the current environment with the query items updated.
  @discardableResult
  func setPercentEncodedQueryItems(_ percentEncodedQueryItems: [URLQueryItem]) -> Self {
    var components = self
    components.percentEncodedQueryItems = percentEncodedQueryItems.isEmpty ? nil : percentEncodedQueryItems
    return components
  }

  /// Appends new percent‑encoded query items to the existing ones.
  ///
  /// Existing items are preserved; if no items exist, the new ones become the sole query.
  ///
  /// - Parameter percentEncodedQueryItems: Array of ``URLQueryItem`` to append.
  /// - Returns: A copy of the current environment with the query items appended.
  @discardableResult
  func appendPercentEncodedQueryItems(_ percentEncodedQueryItems: [URLQueryItem]) -> Self {
    var existing = self.percentEncodedQueryItems ?? []
    existing.append(contentsOf: percentEncodedQueryItems)
    return setPercentEncodedQueryItems(existing)
  }
}
