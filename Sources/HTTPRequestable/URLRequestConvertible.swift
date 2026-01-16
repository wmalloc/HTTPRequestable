//
//  URLRequestConvertible.swift
//
//  Created by Waqar Malik on 9/26/25.
//

import Foundation

/// A lightweight protocol for values that can be converted to a `URLRequest`.
///
/// Conforming types expose a throwing `urlRequest` property that produces a ready-to-send
/// `URLRequest`, making them interchangeable in APIs that perform networking (e.g.,
/// `URLSession`). The protocol refines `Sendable`, so conforming values are safe to pass
/// across concurrency domains in Swift Concurrency.
///
/// - Typical conformers:
///   - `URLRequest` (returns itself)
///   - `URL` or `String` (builds a minimal request from a URL)
///   - Higher-level request builders (e.g., types that assemble method, path, headers, and body)
///
/// - Error semantics:
///   Implementations should throw when a valid request cannot be produced (for example, a
///   malformed URL or missing required components). Prefer domain-specific errors such as
///   `URLError(.badURL)` or your own `HTTPError` type.
///
/// - Thread-safety:
///   Because this protocol refines `Sendable`, conformers must be safe to use across tasks
///   (e.g., be value types or otherwise ensure internal mutation is concurrency-safe).
///
/// - Usage:
///   ```swift
///   func send<R: URLRequestConvertible>(_ convertible: R) async throws -> (Data, URLResponse) {
///     try await URLSession.shared.data(for: convertible.urlRequest)
///   }
///   ```
/// A fully-formed `URLRequest` representation of the receiver.
/// - Returns: A `URLRequest` suitable for use with `URLSession` and related networking APIs.
/// - Throws: An error if a valid request cannot be created (e.g., the underlying URL is
///   invalid or required components are missing).
public protocol URLRequestConvertible: Sendable {
  var urlRequest: URLRequest { get throws }
}

extension URLRequest: URLRequestConvertible {
  public var urlRequest: URLRequest {
    get throws { self }
  }
}

/// Creates a get URLRequest
extension String: URLRequestConvertible {
  public var urlRequest: URLRequest {
    get throws { try URLRequest(url: url) }
  }
}

extension URLComponents: URLRequestConvertible {
  public var urlRequest: URLRequest {
    get throws {
      guard let url else {
        throw URLError(.badURL)
      }
      return URLRequest(url: url)
    }
  }
}
