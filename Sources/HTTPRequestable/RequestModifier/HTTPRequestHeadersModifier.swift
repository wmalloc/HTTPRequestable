//
//  HTTPRequestHeadersModifier.swift
//
//  Created by Waqar Malik on 1/14/26.
//

#if canImport(FoundationNetworking)
public import FoundationNetworking
#else
public import Foundation
#endif
import HTTPTypes

/// A request modifier that injects a predefined set of HTTP header fields.
///
/// The modifier holds an immutable collection of `HTTPField` values.  When
/// applied, the fields are either appended (when missing) or used to replace
/// existing values, depending on the `replaceExisting` policy.  This makes
/// it trivial to add a common set of headers (e.g., `User-Agent`,
/// `Accept‑Encoding`) to every request.
public final class HTTPRequestHeadersModifier: HTTPRequestModifier, @unchecked Sendable {
  /// The collection of header fields that will be applied.
  ///
  /// This property is immutable; all mutation occurs through the
  /// `modify(_:for:)` method.  It is stored as an `HTTPFields`
  /// instance for efficient lookup and concatenation.
  public let headerFields: HTTPFields

  /// Determines whether existing header values are overwritten.
  ///
  /// When `true`, a field from `headerFields` always replaces any
  /// value already present on the request for that name.  When
  /// `false` (the default), a field is only written when no value
  /// exists for that name, preserving any caller‑supplied value.
  public let replaceExisting: Bool

  /// Creates a modifier from an `HTTPFields` collection.
  ///
  /// The default set is defined by `HTTPFields.defaultHeaders` and
  /// typically includes common headers such as `User-Agent`,
  /// `Accept‑Encoding`, and `Accept-Language`.
  ///
  /// - Parameters:
  ///   - headerFields: The headers to apply.
  ///   - replaceExisting: When `true`, fields already present on the
  ///     request are overwritten.  Defaults to `false`.
  public init(headerFields: HTTPFields, replaceExisting: Bool = false) {
    self.headerFields = headerFields
    self.replaceExisting = replaceExisting
  }

  /// Creates a modifier from an arbitrary collection of `HTTPField`s.
  ///
  /// This initializer is handy when you have a list of fields that
  /// already exist as `HTTPField` instances and want to convert them
  /// into the internal `HTTPFields` container.
  ///
  /// - Parameters:
  ///   - fields: A collection of `HTTPField` objects to include in
  ///     the modifier.
  ///   - replaceExisting: When `true`, fields already present on the
  ///     request are overwritten.  Defaults to `false`.
  public init(fields: some Sequence<HTTPField>, replaceExisting: Bool = false) {
    self.headerFields = HTTPFields(fields)
    self.replaceExisting = replaceExisting
  }

  /// Creates a modifier from a dictionary of header names and values.
  ///
  /// Keys are interpreted as raw header field names; they are
  /// validated against `HTTPField.Name`.  Invalid keys are silently
  /// ignored.  Each valid pair becomes an `HTTPField` that will be
  /// appended to the request.
  ///
  /// - Parameters:
  ///   - headers: A dictionary mapping header names to string values.
  ///   - replaceExisting: When `true`, fields already present on the
  ///     request are overwritten.  Defaults to `false`.
  public init(headers: [String: String], replaceExisting: Bool = false) {
    var fields = HTTPFields()
    for (key, value) in headers {
      guard let fieldName = HTTPField.Name(key) else { continue }
      fields.append(HTTPField(name: fieldName, value: value))
    }
    self.headerFields = fields
    self.replaceExisting = replaceExisting
  }

  /// Applies the stored headers to a mutable `HTTPRequest` instance.
  ///
  /// When `replaceExisting` is `true`, every field in `headerFields`
  /// overwrites whatever value is already on the request.  When
  /// `false`, a field is only written when no value exists for that
  /// name, leaving caller‑supplied values untouched.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequest` to modify.  It is mutated in‑place.
  ///   - session: The `URLSession` used for the request.  It is not
  ///     consulted by this modifier, but the signature matches the protocol.
  /// - Throws: Rethrows errors from asynchronous operations if any.
  public func modify(_ request: inout HTTPRequest, for session: URLSession?) async throws {
    for field in headerFields {
      if replaceExisting || request.headerFields[field.name] == nil {
        request.headerFields[field.name] = field.value
      }
    }
  }

  /// Applies the stored headers to a mutable `URLRequest` instance.
  ///
  /// The logic mirrors that of the `HTTPRequest` overload: when
  /// `replaceExisting` is `true` any existing value is overwritten;
  /// otherwise only missing fields are filled in.  The method mutates
  /// the provided `URLRequest` in‑place.
  ///
  /// - Parameters:
  ///   - request: The `URLRequest` to modify.  It is mutated in‑place.
  ///   - session: The `URLSession` used for the request.  This modifier
  ///     does not use it, but the signature must conform to the protocol.
  /// - Throws: Rethrows errors from asynchronous operations if any.
  public func modify(_ request: inout URLRequest, for session: URLSession?) async throws {
    for field in headerFields {
      if replaceExisting || request.value(forHTTPField: field.name) == nil {
        request.setValue(field.value, forHTTPField: field.name)
      }
    }
  }
}

extension HTTPRequestHeadersModifier: ExpressibleByArrayLiteral {
  /// Creates a modifier from an array literal of `HTTPField` instances.
  ///
  /// The `replaceExisting` flag is set to `true` by default,
  /// meaning existing headers will be overwritten.
  ///
  /// - Parameter elements: An array of `HTTPField` elements.
  public convenience init(arrayLiteral elements: HTTPField...) {
    self.init(fields: Array(elements), replaceExisting: true)
  }
}

extension HTTPRequestHeadersModifier: ExpressibleByDictionaryLiteral {
  /// Creates a modifier from a dictionary literal of header names and values.
  ///
  /// Keys are validated as header field names. Invalid keys are ignored.
  /// The `replaceExisting` flag is set to `true` by default.
  ///
  /// - Parameter elements: A variadic list of `(String, String)` pairs.
  public convenience init(dictionaryLiteral elements: (String, String)...) {
    let fields: [HTTPField] = elements.compactMap { item in
      guard let name = HTTPField.Name(item.0) else { return nil }
      return .init(name: name, value: item.1)
    }
    self.init(fields: fields, replaceExisting: true)
  }
}

public extension HTTPRequestHeadersModifier {
  /// Default instance with standard headers.
  ///
  /// This instance uses `HTTPFields.defaultHeaders` as its header fields,
  /// which typically includes common headers such as `User-Agent`,
  /// `Accept-Encoding`, and `Accept-Language`.
  static var defaultHeaderModifier: HTTPRequestHeadersModifier {
    HTTPRequestHeadersModifier(headerFields: .defaultHeaders)
  }
}
