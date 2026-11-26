//
//  HTTPContentType.swift
//
//  Created by Waqar Malik on 4/27/23.
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
#endif

/// A media type, such as `application/json` or `text/html; charset=utf-8` (RFC 9110 section 8.3.1),
/// used in `Content-Type` and `Accept` headers.
///
/// A content type is checked when it is created: it must be `type/subtype` followed by any number of
/// `; name=value` parameters, where each name, type and subtype is a token and each value is a token or
/// a quoted-string. Type, subtype and parameter names are compared without regard to case.
///
/// ```swift
/// let type = HTTPContentType(rawValue: "Text/HTML; Charset=UTF-8")  // type "text", subtype "html"
/// type?.parameters["charset"]  // "UTF-8"
/// HTTPContentType(rawValue: "not a type")  // nil
/// ```
@frozen
public struct HTTPContentType: RawRepresentable, Hashable, Sendable {
  /// The content type as written, without leading or trailing whitespace.
  public let rawValue: String

  /// The type, such as `text` in `text/html`, lowercased. `*` in a media range such as `*/*`.
  public let type: String

  /// The subtype, such as `html` in `text/html`, lowercased. `*` in a media range such as `text/*`.
  public let subtype: String

  /// The parameters, such as `charset`, with names lowercased and quoted values unquoted.
  public let parameters: [String: String]

  /// The type and subtype without parameters, lowercased, such as `text/html`.
  public var mimeType: String {
    "\(type)/\(subtype)"
  }

  /// Creates a content type from a media type such as `text/html; charset=utf-8`.
  ///
  /// - Parameter rawValue: The media type. Leading and trailing whitespace is removed.
  /// - Returns: `nil` when `rawValue` is not a valid media type, for example when it has no `/`,
  ///   contains a space or control character outside a quoted parameter value, or names a parameter
  ///   twice.
  public init?(rawValue: String) {
    let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let mediaType = HTTPFieldValueSyntax.parseMediaType(trimmed) else {
      return nil
    }
    var parameters: [String: String] = [:]
    for parameter in mediaType.parameters {
      // A repeated parameter is ambiguous, so it is rejected rather than resolved either way.
      guard parameters.updateValue(parameter.value, forKey: parameter.name) == nil else {
        return nil
      }
    }
    self.rawValue = trimmed
    self.type = mediaType.type
    self.subtype = mediaType.subtype
    self.parameters = parameters
  }

  /// Whether `contentType` is in this media range, as used to check a response against `Accept`.
  ///
  /// `*/*` matches every content type and `text/*` every `text` subtype; otherwise the type and subtype
  /// must be equal. Parameters are ignored, so `application/json` matches
  /// `application/json; charset=utf-8`.
  ///
  /// - Parameter contentType: The content type to check, such as a response's `Content-Type`.
  /// - Returns: `true` when `contentType` is in this range.
  public func matches(_ contentType: HTTPContentType) -> Bool {
    if type == "*" {
      return subtype == "*"
    }
    return type == contentType.type && (subtype == "*" || subtype == contentType.subtype)
  }

  /// Splits a comma-separated list, such as an `Accept` value, into content types.
  ///
  /// Commas inside quoted parameter values do not separate entries. Entries that are blank or not valid
  /// media types are left out.
  ///
  /// - Parameter value: A string containing one or more content types, separated by commas.
  /// - Returns: The valid content types, in order.
  public static func contentTypes(for value: String) -> [Self] {
    HTTPFieldValueSyntax.listElements(value).compactMap(Self.init(rawValue:))
  }

  /// Two content types are equal when their type, subtype and parameters are, comparing type, subtype
  /// and parameter names without regard to case. The `charset` value is also compared without regard
  /// to case; other parameter values must match exactly.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.type == rhs.type && lhs.subtype == rhs.subtype && lhs.comparableParameters == rhs.comparableParameters
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(type)
    hasher.combine(subtype)
    hasher.combine(comparableParameters)
  }

  /// The parameters with the `charset` value lowercased, since charset names ignore case.
  private var comparableParameters: [String: String] {
    var parameters = parameters
    if let charset = parameters["charset"] {
      parameters["charset"] = charset.lowercased()
    }
    return parameters
  }
}

extension HTTPContentType {
  /// The media range an `Accept` list element names, without its parameters, or `nil` when the element
  /// is not a valid media range, has an invalid `q`, or has `q=0`, which marks it as not acceptable.
  static func acceptedRange(_ element: String) -> HTTPContentType? {
    guard let range = HTTPContentType(rawValue: element) else {
      return nil
    }
    if let quality = range.parameters["q"] {
      guard let value = HTTPFieldValueSyntax.parseQValue(quality), value > 0 else {
        return nil
      }
    }
    // Only the type and subtype take part in matching, so parameters, including q, are not kept.
    return HTTPContentType(rawValue: range.mimeType)
  }
}

/// A type that can be identified.
extension HTTPContentType: Identifiable {
  /// The unique identifier for the content type.
  public var id: String {
    rawValue
  }
}

/// A type that can be initialized with a string literal.
extension HTTPContentType: ExpressibleByStringLiteral {
  /// Creates a content type from a literal such as `"application/json"`.
  ///
  /// - Parameter value: The media type.
  /// - Precondition: `value` is a valid media type.
  public init(stringLiteral value: String) {
    guard let contentType = Self(rawValue: value) else {
      preconditionFailure("\"\(value)\" is not a valid media type")
    }
    self = contentType
  }
}

/// A type with a customized textual representation.
extension HTTPContentType: CustomStringConvertible {
  /// A textual representation of the content type.
  public var description: String {
    rawValue
  }
}

/// A type that can be represented as a string in a lossless, unambiguous way.
extension HTTPContentType: LosslessStringConvertible {
  /// Creates a content type from a media type such as `text/html; charset=utf-8`.
  ///
  /// - Parameter description: The media type.
  /// - Returns: `nil` when `description` is not a valid media type.
  public init?(_ description: String) {
    self.init(rawValue: description)
  }
}

/// A type that supplies a custom description for playground logging.
extension HTTPContentType: CustomPlaygroundDisplayConvertible {
  /// A custom description for playground logging.
  public var playgroundDescription: Any {
    description
  }
}

extension HTTPContentType: Encodable {
  /// Encodes the content type to the given encoder.
  ///
  /// - Parameter encoder: The encoder to write data to.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

extension HTTPContentType: Decodable {
  /// Decodes a content type from a string.
  ///
  /// - Parameter decoder: The decoder to read data from.
  /// - Throws: `DecodingError.dataCorrupted` when the string is not a valid media type, or another
  ///   decoding error.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    let rawString = try container.decode(String.self)
    guard let contentType = Self(rawValue: rawString) else {
      // The value is left out of the message, so it is not repeated where errors get logged.
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "The value is not a valid media type")
    }
    self = contentType
  }
}

public extension HTTPContentType {
  /// Any content type.
  @inlinable
  static var any: Self {
    "*/*"
  }

  /// CSS content type.
  @inlinable
  static var css: Self {
    "text/css"
  }

  /// URL-encoded Form Data.
  @inlinable
  static var formEncoded: Self {
    "application/x-www-form-urlencoded"
  }

  /// GIF content type.
  @inlinable
  static var gif: Self {
    "image/gif"
  }

  /// HTML content type.
  @inlinable
  static var html: Self {
    "text/html"
  }

  /// JPEG content type.
  @inlinable
  static var jpeg: Self {
    "image/jpeg"
  }

  /// JSON content type.
  @inlinable
  static var json: Self {
    "application/json"
  }

  /// JSON content type with UTF-8 encoding.
  @inlinable
  static var jsonUTF8: Self {
    "application/json; charset=utf-8"
  }

  /// Multi-part form data.
  @inlinable
  static var multipartForm: Self {
    "multipart/form-data"
  }

  /// Octet Stream content type.
  @inlinable
  static var octetStream: Self {
    "application/octet-stream"
  }

  /// Patch JSON content type.
  @inlinable
  static var patchjson: Self {
    "application/json-patch+json"
  }

  /// PNG content type.
  @inlinable
  static var png: Self {
    "image/png"
  }

  /// SVG content type.
  @inlinable
  static var svg: Self {
    "image/svg+xml"
  }

  /// Plain Text content type.
  @inlinable
  static var textPlain: Self {
    "text/plain"
  }

  /// XML content type.
  @inlinable
  static var xml: Self {
    "application/xml"
  }
}
