//
//  HTTPField+Common.swift
//
//  Created by Waqar Malik on 4/28/23.
//

import Foundation
import HTTPTypes

/// Extension providing static methods for creating HTTP fields (headers) with specific values.
public extension HTTPField {
  /// Creates an `HTTPField` instance representing the `Accept` header field with a raw string value.
  /// - Parameter value: A string representing the desired MIME types to accept.
  /// - Returns: An `HTTPField` instance with name `Accept` and the provided value.
  static func accept(_ value: String) -> Self {
    .init(name: .accept, value: value)
  }

  /// Creates an `HTTPField` instance representing the `Accept` header field with a content type value.
  /// - Parameter value: An instance of `HTTPContentType` representing the desired MIME types to accept.
  /// - Returns: An `HTTPField` instance with name `Accept` and the provided content type value as a string.
  static func accept(_ value: HTTPContentType) -> Self {
    .init(name: .accept, value: value.rawValue)
  }

  /// Creates an `HTTPField` instance representing the `Accept-Language` header field with a raw string value.
  /// - Parameter value: A string representing the languages to accept.
  /// - Returns: An `HTTPField` instance with name `Accept-Language` and the provided value.
  static func acceptLanguage(_ value: String) -> Self {
    .init(name: .acceptLanguage, value: value)
  }

  /// Creates an `HTTPField` instance representing the `Accept-Encoding` header field with a raw string value.
  /// - Parameter value: A string representing the content encodings to accept.
  /// - Returns: An `HTTPField` instance with name `Accept-Encoding` and the provided value.
  static func acceptEncoding(_ value: String) -> Self {
    .init(name: .acceptEncoding, value: value)
  }

  /// Creates an `HTTPField` instance representing the `Authorization` header field with a raw string value.
  /// - Parameter value: A string representing the authorization information (e.g., `bearer token`).
  /// - Returns: An `HTTPField` instance with name `Authorization` and the provided value.
  static func authorization(_ value: String) -> Self {
    .init(name: .authorization, value: value)
  }

  /// Convenience method to create an `Authorization` header field with a bearer token.
  /// - Parameter token: A string representing the bearer token.
  /// - Returns: An `HTTPField` instance with name `Authorization` and the value set as `Bearer {token}`.
  static func authorization(bearerToken: String) -> Self {
    authorization("Bearer \(bearerToken)")
  }

  /// Creates an `HTTPField` instance representing the `Content-Type` header field with a raw string value.
  /// - Parameter value: A string representing the MIME type of the content.
  /// - Returns: An `HTTPField` instance with name `Content-Type` and the provided value.
  static func contentType(_ value: String) -> Self {
    .init(name: .contentType, value: value)
  }

  /// Convenience method to create a "Content-Type" header field with an `HTTPContentType` instance.
  /// - Parameter value: An instance of `HTTPContentType` representing the MIME type of the content.
  /// - Returns: An `HTTPField` instance with name `Content-Type` and the provided content type value as a string.
  static func contentType(_ value: HTTPContentType) -> Self {
    contentType(value.rawValue)
  }

  /// Creates an `HTTPField` instance representing the `User-Agent` header field with a raw string value.
  /// - Parameter value: A string representing the user agent identifier.
  /// - Returns: An `HTTPField` instance with name `User-Agent` and the provided value.
  static func userAgent(_ value: String) -> Self {
    .init(name: .userAgent, value: value)
  }

  /// Creates an `HTTPField` instance representing the `Content-Disposition` header field with a raw string value.
  /// - Parameter value: A string representing the content disposition information.
  /// - Returns: An `HTTPField` instance with name `Content-Disposition` and the provided value.
  static func contentDisposition(_ value: String) -> Self {
    .init(name: .contentDisposition, value: value)
  }

  /// Creates an `HTTPField` instance representing the `Content-Disposition` header field with a raw string value.
  /// - Parameter value: A string representing the content disposition information.
  /// - Returns: An `HTTPField` instance with name `Content-Disposition` and the provided value.
      static func contentDisposition(_ value: Quality) -> Self {
    .init(name: .contentDisposition, value: value.encoded)
  }
}
