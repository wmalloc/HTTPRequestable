//
//  HTTPFIeld+Default.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 10/25/24.
//

import Foundation
import HTTPTypes

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
