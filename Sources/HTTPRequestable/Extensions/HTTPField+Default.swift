//
//  HTTPField+Default.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 10/25/24.
//

import Foundation
import HTTPTypes

/// Convenience initializer for creating a header field that represents
/// an HTTP content‑type.
///
/// This extension allows you to construct an `HTTPField` directly from
/// a `HTTPContentType` value, avoiding the need to access its raw string
/// representation manually.  It is particularly useful when setting the
/// `Content-Type` header in a request.
///
/// - Parameters:
///   - name: The header field name, typically `.contentType`
///     (the `Content‑Type` header).  The type is a strongly typed
///     `HTTPField.Name` enum to prevent typos.
///   - contentType: The media type that the request body conforms
///     to.  The enum’s raw value (e.g., `"application/json"`) is
///     used as the header field’s value.
///
/// Example:
/// ```swift
/// let contentTypeField = HTTPField(name: .contentType, contentType: .json)
/// ```
/// This creates a header field equivalent to `Content-Type: application/json`.
public extension HTTPField {
  init(name: HTTPField.Name, contentType: HTTPContentType) {
    self.init(name: name, value: contentType.rawValue)
  }
}

public extension HTTPField {
  /// See the [Accept-Encoding HTTP header documentation](https://tools.ietf.org/html/rfc7230#section-4.2.3).
  static var defaultAcceptEncoding: Self {
    HTTPField(name: .acceptEncoding, value: Quality(values: ["br", "gzip", "deflate"]).encoded)
  }

  /// See the [Accept-Language HTTP header documentation](https://tools.ietf.org/html/rfc7231#section-5.3.5).
  static var defaultAcceptLanguage: Self {
    HTTPField(name: .acceptLanguage, value: Quality(values: Array(Locale.preferredLanguages.prefix(6))).encoded)
  }

  /// See the [User-Agent header](https://tools.ietf.org/html/rfc7231#section-5.5.3).
  static var defaultUserAgent: Self {
    HTTPField.userAgent(String.url_userAgent)
  }
}
