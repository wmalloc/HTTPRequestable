//
//  HTTPField+Common.swift
//
//  Created by Waqar Malik on 4/28/23.
//

import Foundation
import HTTPTypes

public extension HTTPField {
  static func accept(_ value: String) -> Self {
    .init(name: .accept, value: value)
  }

  static func accept(_ value: HTTPContentType) -> Self {
    .init(name: .accept, value: value.rawValue)
  }

  static func acceptLanguage(_ value: String) -> Self {
    .init(name: .acceptLanguage, value: value)
  }

  static func acceptEncoding(_ value: String) -> Self {
    .init(name: .acceptEncoding, value: value)
  }

  static func authorization(_ value: String) -> Self {
    .init(name: .authorization, value: value)
  }

  static func authorization(token: String) -> Self {
    authorization("Bearer \(token)")
  }

  static func contentType(_ value: String) -> Self {
    .init(name: .contentType, value: value)
  }

  static func contentType(_ value: HTTPContentType) -> Self {
    contentType(value.rawValue)
  }

  static func userAgent(_ value: String) -> Self {
    .init(name: .userAgent, value: value)
  }

  static func contentDisposition(_ value: String) -> Self {
    .init(name: .contentDisposition, value: value)
  }

  /// See the [User-Agent header](https://tools.ietf.org/html/rfc7231#section-5.5.3).
  static var defaultUserAgent: Self {
    .userAgent(String.url_userAgent)
  }

  static var defaultAcceptLanguage: Self {
    .acceptLanguage(Locale.preferredLanguages.prefix(6).url_qualityEncoded())
  }

  static var defaultAcceptEncoding: Self {
    .acceptEncoding(["br", "gzip", "deflate"].url_qualityEncoded())
  }
}
