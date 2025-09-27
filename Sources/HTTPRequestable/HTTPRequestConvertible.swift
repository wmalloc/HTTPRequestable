//
//  HTTPRequestConvertible.swift
//
//  Created by Waqar Malik on 9/26/25.
//

import Foundation
import HTTPTypes
import HTTPTypesFoundation

/// A lightweight protocol for types that can produce a fully formed `HTTPTypes.HTTPRequest`.
///
/// Conform to `HTTPRequestConvertible` when you already have enough information to construct
/// a complete `HTTPRequest` (method, scheme, authority/host, path, query, and header fields).
/// This protocol is intentionally minimal—just a single throwing property—so you can adopt it
/// for existing request builders, request models, or routing enums without inheriting any
/// additional behavior.
///
/// Concurrency
/// - Conforming types must be `Sendable`. Ensure any state used to construct the request is
///   safe to access across concurrency domains (e.g., avoid shared mutable state).
/// - The `httpRequest` property is synchronous and may throw. If you need asynchronous work
///   (e.g., reading from disk or keychain), perform that before accessing `httpRequest`.
///
/// Throwing
/// - Throw an error when a complete `HTTPRequest` cannot be produced (for example, when a URL
///   is invalid or required components are missing).
///
/// Usage
/// - Use the resulting `HTTPRequest` directly with `HTTPTypesFoundation` to create a `URLRequest`,
///   or pass it to your networking layer as-is.
/// - If you need a higher-level, configurable builder (e.g., with base URL, default headers,
///   and query composition), consider using `HTTPRequestConfigurable` instead.
///
/// Example
/// ```swift
/// struct GetUserRoute: HTTPRequestConvertible {
///     let userID: String
///
///     var httpRequest: HTTPRequest {
///         get throws {
///             var components = URLComponents()
///             components.scheme = "https"
///             components.host = "api.example.com"
///             components.path = "/v1/users/\(userID)"
///
///             guard let url = components.url else { throw URLError(.badURL) }
///             return try HTTPRequest(method: .get, url: url)
///         }
///     }
/// }
/// ```
///
/// See Also
/// - `HTTPRequestConfigurable` for composable request building
/// - `HTTPTypes.HTTPRequest`
/// - `HTTPTypesFoundation.URLRequest.init(httpRequest:)`
///
/// Requirements:
/// - `httpRequest`: A fully formed `HTTPRequest` ready to execute or to convert into a `URLRequest`.
public protocol HTTPRequestConvertible: Sendable {
  /// returns fully formed request
  var httpRequest: HTTPRequest { get throws }
}

extension String: HTTPRequestConvertible {
  public var httpRequest: HTTPRequest {
    get throws {
      try HTTPRequest(url: url)
    }
  }
}

extension URLComponents: HTTPRequestConvertible {
  public var httpRequest: HTTPRequest {
    get throws {
      guard let url else {
        throw URLError(.badURL)
      }
      return HTTPRequest(url: url)
    }
  }
}
