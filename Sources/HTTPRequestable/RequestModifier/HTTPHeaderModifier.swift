//
//  HTTPHeaderModifier.swift
//
//  Created by Waqar Malik on 1/14/26.
//

import Foundation
import HTTPTypes

/// A request modifier that injects a predefined set of HTTP header fields.
///
/// The modifier holds an immutable collection of `HTTPField` values.  When
/// applied, the fields are appended to the request’s header list if they
/// are not already present.  This makes it trivial to add a common set of
/// headers (e.g., `User-Agent`, `Accept‑Encoding`) to every request.
public final class HTTPHeaderModifier: HTTPRequestModifier, @unchecked Sendable {
  /// The collection of header fields that will be applied.
  ///
  /// This property is immutable; all mutation occurs through the
  /// `modify(_:for:)` method.  It is stored as an `HTTPFields`
  /// instance for efficient lookup and concatenation.
  ///
  public let headerFields: HTTPFields

  /// Creates a modifier using the library’s built‑in default headers.
  ///
  /// The default set is defined by `HTTPFields.defaultHeaders` and
  /// typically includes common headers such as `User-Agent`,
  /// `Accept‑Encoding`, and `Accept-Language`.
  ///
  /// - Parameter headerFields: The headers to apply.  If omitted,
  ///   the predefined defaults are used.
  public init(headerFields: HTTPFields) {
    self.headerFields = headerFields
  }

  /// Creates a modifier from an arbitrary collection of `HTTPField`s.
  ///
  /// This initializer is handy when you have a list of fields that
  /// already exist as `HTTPField` instances and want to convert them
  /// into the internal `HTTPFields` container.
  ///
  /// - Parameter fields: A collection of `HTTPField` objects to
  ///   include in the modifier.
  public init(fields: any Collection<HTTPField>) {
    self.headerFields = HTTPFields(fields)
  }

  /// Creates a modifier from a dictionary of header names and values.
  ///
  /// Keys are interpreted as raw header field names; they are
  /// validated against `HTTPField.Name`.  Invalid keys are silently
  /// ignored.  Each valid pair becomes an `HTTPField` that will be
  /// appended to the request.
  ///
  /// - Parameter headers: A dictionary mapping header names to
  ///   string values.
  public init(headers: [String: String]) {
    var fields = HTTPFields()
    for (key, value) in headers {
      guard let fieldName = HTTPField.Name(key) else { continue }
      let field = HTTPField(name: fieldName, value: value)
      fields.append(field)
    }
    self.headerFields = fields
  }

  /// Applies the default headers to a mutable `HTTPRequest` instance.
  ///
  /// If any of the three common header fields are missing, they will be
  /// appended with their default values.  Existing values are left untouched.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequest` to modify.  It is mutated in‑place.
  ///   - session: The `URLSession` used for the request.  It is not
  ///     consulted by this modifier, but the signature matches the protocol.
  ///
  public func modify(_ request: inout HTTPRequest, for session: URLSession?) async throws {
    for field in headerFields where request.headerFields[field.name] == nil {
      request.headerFields.append(field)
    }
  }

  /// Applies the default headers to a mutable `URLRequest` instance.
  ///
  /// The logic mirrors that of the `HTTPRequest` overload: any missing
  /// header field is set to its default value.  The method mutates the
  /// provided `URLRequest` in‑place.
  ///
  /// - Parameters:
  ///   - request: The `URLRequest` to modify.  It is mutated in‑place.
  ///   - session: The `URLSession` used for the request.  This modifier
  ///     does not use it, but the signature must conform to the protocol.
  ///
  public func modify(_ request: inout URLRequest, for session: URLSession?) async throws {
    for field in headerFields where request.value(forHTTPField: field.name) == nil {
      request.setValue(field.value, forHTTPField: field.name)
    }
  }
}

public extension HTTPHeaderModifier {
  /// Default instance with standard headers
  static var defaultHeaderModifier: HTTPHeaderModifier {
    HTTPHeaderModifier(headerFields: .defaultHeaders)
  }
}
