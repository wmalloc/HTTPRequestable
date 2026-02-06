//
//  TestIdentifiable.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/30/25.
//

import Foundation
import HTTPTypes

/// A protocol that exposes a *test* identifier for debugging or logging purposes.
///
/// Types conforming to `TestIdentifiable` provide an optional string that can be used by
/// tooling, test harnesses, or the networking layer to identify requests, URLs,
/// or other entities in logs or assertions.
public protocol TestIdentifiable {
  /// The optional identifier associated with this instance.
  var testIdentifier: String? { get }
}

// MARK: - Conformances

extension String: TestIdentifiable {
  /// Returns the string itself as the test identifier.
  public var testIdentifier: String? {
    self
  }
}

extension URL: TestIdentifiable {
  /// Returns the absolute URL string as the test identifier.
  public var testIdentifier: String? {
    absoluteString
  }
}

extension URLRequest: TestIdentifiable {
  /// Returns a test identifier by first checking for an `X-Test-Identifier` HTTP header.
  /// If not present, it returns the absolute URL string of the request.
  public var testIdentifier: String? {
    value(forHTTPHeaderField: .xTestIdentifier) ?? url?.testIdentifier
  }
}

extension HTTPRequest: TestIdentifiable {
  /// Returns a test identifier by first checking for an `X-Test-Identifier` header in the request's
  /// header fields. If not present, it returns the absolute URL string of the request.
  public var testIdentifier: String? {
    headerFields[.xTestIdentifier] ?? url?.testIdentifier
  }
}
