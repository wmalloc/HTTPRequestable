//
//  URLConvertible.swift
//
//  Created by Waqar Malik on 9/26/25.
//

import Foundation

/// A lightweight protocol for values that can be converted to a valid `URL`.
///
/// Conforming types expose a throwing `url` property that produces a `URL`,
/// allowing them to be used interchangeably in APIs that require a URL (for example,
/// when constructing HTTP requests).
///
/// This protocol refines `Sendable`, so conforming values are safe to pass across
/// concurrency domains in Swift Concurrency.
///
/// - Usage:
///   Types like `URL` and `String` commonly conform, enabling code such as:
///   ```swift
///   func fetch(from convertible: URLConvertible) async throws {
///     let url = try convertible.url
///     // Use `url` to build a request...
///   }
///
///   try await fetch(from: "https://example.com")
///   try await fetch(from: URL(string: "https://example.com/resource")!)
///   ```
///
/// - Throws:
///   Implementations should throw if a valid URL cannot be produced (e.g., a malformed
///   string). Prefer throwing `URLError(.badURL)` or a domain-specific error.
///
/// - Notes:
///   Implementations may perform validation and percent-encoding as needed to produce
///   a fully-formed, absolute URL suitable for network requests.
///
/// - SeeAlso: `URLRequestConvertible`, `HTTPRequestConvertible`
///
/// The `url` property returns a validated, fully-formed URL representation of the receiver.
/// - Returns: A `URL` suitable for use in networking or file operations.
/// - Throws: An error if the value cannot be represented as a valid URL.
public protocol URLConvertible: Sendable {
  var url: URL { get throws }
}

extension URL: URLConvertible {
  public var url: URL {
    get throws { self }
  }
}

extension String: URLConvertible {
  public var url: URL {
    get throws {
      guard let url = URL(string: self) else {
        throw URLError(.badURL)
      }
      return url
    }
  }
}
