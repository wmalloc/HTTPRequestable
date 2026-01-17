//
//  DefaultHeadersModifier.swift
//
//  Created by Waqar Malik on 1/14/26.
//

import Foundation
import HTTPTypes

public final class DefaultHeadersModifier: HTTPRequestModifier {
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
    if !request.headerFields.contains(.userAgent) {
      request.headerFields.append(.defaultUserAgent)
    }
    if !request.headerFields.contains(.acceptEncoding) {
      request.headerFields.append(.defaultAcceptEncoding)
    }
    if !request.headerFields.contains(.acceptLanguage) {
      request.headerFields.append(.defaultAcceptLanguage)
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
    if request.value(forHTTPField: .userAgent) == nil {
      request.setValue(HTTPField.defaultUserAgent.value, forHTTPField: .userAgent)
    }
    if request.value(forHTTPField: .acceptEncoding) == nil {
      request.setValue(HTTPField.defaultAcceptEncoding.value, forHTTPField: .acceptEncoding)
    }
    if request.value(forHTTPField: .acceptLanguage) == nil {
      request.setValue(HTTPField.defaultAcceptLanguage.value, forHTTPField: .acceptLanguage)
    }
  }
}
