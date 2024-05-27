//
//  HTTPContentType.swift
//
//  Created by Waqar Malik on 4/27/23.
//

import Foundation

/// <#Description#>
public struct HTTPContentType: RawRepresentable, Hashable, Sendable {
  public var rawValue: String

  public init(rawValue: String) {
    self.rawValue = rawValue
  }
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
  /// Any content type
  static var any: Self { .init(rawValue: "*/*") }

  /// CSS content type
  static var css: Self { .init(rawValue: "text/css") }

  /// Form Data
  static var formData: Self { .init(rawValue: "form-data") }

  /// URLencoded Form Data
  static var formEncoded: Self { .init(rawValue: "application/x-www-form-urlencoded") }

  /// GIF
  /// https://www.rfc-editor.org/rfc/rfc2158.html
  static var gif: Self { .init(rawValue: "image/gif") }

  /// HTML
  static var html: Self { .init(rawValue: "text/html") }

  /// JPEG
  /// https://www.rfc-editor.org/rfc/rfc2158.html
  static var jpeg: Self { .init(rawValue: "image/jpeg") }

  /// The application/json Media Type for JavaScript Object Notation (JSON) data
  /// https://datatracker.ietf.org/doc/html/rfc4627
  static var json: Self { .init(rawValue: "application/json") }

  /// The application/json Media Type for JavaScript Object Notation (JSON) data
  /// https://datatracker.ietf.org/doc/html/rfc4627
  static var jsonUTF8: Self { .init(rawValue: "application/json; charset=utf-8") }

  /// Multi-part form data
  static var multipartForm: Self { .init(rawValue: "multipart/form-data") }

  /// Octet Stream
  static var octetStream: Self { .init(rawValue: "application/octet-stream") }

  /// Patch JSON
  static var patchjson: Self { .init(rawValue: "application/json-patch+json") }

  /// PNG Media Type for Portable Network Graphics
  static var png: Self { .init(rawValue: "image/png") }

  /// PDF Media Type for Portable Document Format
  static var svg: Self { .init(rawValue: "image/svg+xml") }

  /// Plain Text
  static var textPlain: Self { .init(rawValue: "text/plain") }

  /// XML
  static var xml: Self { .init(rawValue: "application/xml") }
}
