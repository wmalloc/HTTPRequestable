//
//  HTTPContentType.swift
//
//  Created by Waqar Malik on 4/27/23.
//

import Foundation

/// Request Content types
@frozen
public struct HTTPContentType: RawRepresentable, Hashable, Sendable {
  public var rawValue: String // ISOLatin1String

  public init(rawValue: String) {
    self.rawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// Returns just the mimeType
  public var mimeType: String {
    let parts = rawValue.split(separator: ";", maxSplits: 1)
    guard let first = parts.first else {
      return rawValue
    }
    return String(first)
  }

  /// Split the string and make the content types from mimetype only
  public static func contentTypes(for value: String) -> [Self] {
    guard !value.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
    return value
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .compactMap { header in
        let parts = header.split(separator: ";", maxSplits: 1)
        return parts.first.map(String.init)
      }
      .compactMap(Self.init(rawValue:))
  }
}

///  A type that can be Identified
extension HTTPContentType: Identifiable {
  public var id: String { rawValue }
}

///  A type that can be initialized with a string literal.
extension HTTPContentType: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(rawValue: value)
  }
}

/// A type with a customized textual representation.
extension HTTPContentType: CustomStringConvertible {
  public var description: String {
    rawValue
  }
}

/// A type that can be represented as a string in a lossless, unambiguous way.
extension HTTPContentType: LosslessStringConvertible {
  public init?(_ description: String) {
    self.init(rawValue: description)
  }
}

/// A type that supplies a custom description for playground logging.
extension HTTPContentType: CustomPlaygroundDisplayConvertible {
  public var playgroundDescription: Any {
    description
  }
}

extension HTTPContentType: Encodable {
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}

extension HTTPContentType: Decodable {
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.rawValue = try container.decode(String.self)
  }
}

public extension HTTPContentType {
  /// Allow Comparison of raw string
  static func == (lhs: HTTPContentType, rhs: StringLiteralType) -> Bool {
    lhs.rawValue == rhs
  }
}

public extension HTTPContentType {
  /// Any content type
  static var any: Self { "*/*" }

  /// CSS content type
  static var css: Self { "text/css" }

  /// Form Data
  static var formData: Self { "form-data" }

  /// URLencoded Form Data
  static var formEncoded: Self { "application/x-www-form-urlencoded" }

  /// GIF
  /// https://www.rfc-editor.org/rfc/rfc2158.html
  static var gif: Self { "image/gif" }

  /// HTML
  static var html: Self { "text/html" }

  /// JPEG
  /// https://www.rfc-editor.org/rfc/rfc2158.html
  static var jpeg: Self { "image/jpeg" }

  /// The application/json Media Type for JavaScript Object Notation (JSON) data
  /// https://datatracker.ietf.org/doc/html/rfc4627
  static var json: Self { "application/json" }

  /// The application/json Media Type for JavaScript Object Notation (JSON) data
  /// https://datatracker.ietf.org/doc/html/rfc4627
  static var jsonUTF8: Self { "application/json; charset=utf-8" }

  /// Multi-part form data
  static var multipartForm: Self { "multipart/form-data" }

  /// Octet Stream
  static var octetStream: Self { "application/octet-stream" }

  /// Patch JSON
  static var patchjson: Self { "application/json-patch+json" }

  /// PNG Media Type for Portable Network Graphics
  static var png: Self { "image/png" }

  /// PDF Media Type for Portable Document Format
  static var svg: Self { "image/svg+xml" }

  /// Plain Text
  static var textPlain: Self { "text/plain" }

  /// XML
  static var xml: Self { "application/xml" }
}
