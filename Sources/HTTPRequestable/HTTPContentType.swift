//
//  HTTPContentType.swift
//
//  Created by Waqar Malik on 4/27/23.
//

import Foundation

@frozen
public struct HTTPContentType: RawRepresentable, Hashable, Sendable {
  /// The raw string value of the content type.
  public var rawValue: String // ISOLatin1String

  /// The MIME type extracted from the raw value.
  public var mimeType: String

  /// Initializes a new `HTTPContentType` with the given raw value.
  ///
  /// - Parameter rawValue: The raw string value of the content type.
  public init(rawValue: String) {
    self.rawValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
    self.mimeType = Self.mimeType(for: self.rawValue) ?? ""
  }

  /// Splits a string and creates content types from the MIME type only.
  ///
  /// - Parameter value: A string containing one or more content types, separated by commas.
  /// - Returns: An array of `HTTPContentType` objects.
  public static func contentTypes(for value: String) -> [Self] {
    guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
    return value.split(separator: ",")
      .compactMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .map(Self.init(rawValue:))
  }

  static func mimeType(for value: String) -> String? {
    value.split(separator: ";", maxSplits: 1).first.map(String.init)?.trimmingCharacters(in: .whitespacesAndNewlines)
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
  /// Initializes a new `HTTPContentType` with a string literal.
  ///
  /// - Parameter value: The string literal value.
  public init(stringLiteral value: String) {
    self.init(rawValue: value)
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
  /// Initializes a new `HTTPContentType` from a description string.
  ///
  /// - Parameter description: The description string.
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
  /// Decodes a new `HTTPContentType` from the given decoder.
  ///
  /// - Parameter decoder: The decoder to read data from.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.rawValue = try container.decode(String.self)
    self.mimeType = Self.mimeType(for: rawValue) ?? ""
  }
}

public extension HTTPContentType {
  /// Allows comparison of raw string values.
  static func == (lhs: HTTPContentType, rhs: StringLiteralType) -> Bool {
    lhs.mimeType == HTTPContentType.mimeType(for: rhs)
  }
}

public extension HTTPContentType {
  /// Any content type.
  static var any: Self {
    "*/*"
  }

  /// CSS content type.
  static var css: Self {
    "text/css"
  }

  /// Form Data.
  static var formData: Self {
    "form-data"
  }

  /// URL-encoded Form Data.
  static var formEncoded: Self {
    "application/x-www-form-urlencoded"
  }

  /// GIF content type.
  static var gif: Self {
    "image/gif"
  }

  /// HTML content type.
  static var html: Self {
    "text/html"
  }

  /// JPEG content type.
  static var jpeg: Self {
    "image/jpeg"
  }

  /// JSON content type.
  static var json: Self {
    "application/json"
  }

  /// JSON content type with UTF-8 encoding.
  static var jsonUTF8: Self {
    "application/json; charset=utf-8"
  }

  /// Multi-part form data.
  static var multipartForm: Self {
    "multipart/form-data"
  }

  /// Octet Stream content type.
  static var octetStream: Self {
    "application/octet-stream"
  }

  /// Patch JSON content type.
  static var patchjson: Self {
    "application/json-patch+json"
  }

  /// PNG content type.
  static var png: Self {
    "image/png"
  }

  /// SVG content type.
  static var svg: Self {
    "image/svg+xml"
  }

  /// Plain Text content type.
  static var textPlain: Self {
    "text/plain"
  }

  /// XML content type.
  static var xml: Self {
    "application/xml"
  }
}
