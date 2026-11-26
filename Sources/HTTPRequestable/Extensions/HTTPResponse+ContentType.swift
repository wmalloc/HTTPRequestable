//
//  HTTPResponse+ContentType.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/6/25.
//

import Foundation
import HTTPTypes

public extension HTTPResponse {
  /// The media type in the response's `Content-Type` header.
  ///
  /// `Content-Type` holds a single media type, so a comma, for example inside a quoted parameter
  /// value, does not separate it into several.
  ///
  /// Returns `nil` if the header is missing or blank, or is not a valid media type.
  var contentType: HTTPContentType? {
    headerFields[.contentType].flatMap(HTTPContentType.init(rawValue:))
  }

  /// The media type in the response's `Content-Type` header, as a set of one.
  ///
  /// Returns `nil` if the header is missing or blank, or is not a valid media type. See ``contentType``.
  var contentTypes: Set<HTTPContentType>? {
    contentType.map { [$0] }
  }
}
