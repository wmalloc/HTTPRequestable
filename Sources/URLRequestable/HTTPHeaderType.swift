//
//  HTTPHeaderType.swift
//
//  Created by Waqar Malik on 4/27/23.
//

import Foundation

public typealias HTTPHeaderType = String

public extension HTTPHeaderType {
  static let accept = "Accept"
  static let authorization = "Authorization"
  static let acceptCharset = "Accept-Charset"
  static let acceptEncoding = "Accept-Encoding"
  static let acceptLanguage = "Accept-Language"
  static let cacheControl = "Cache-Control"
  static let contentDisposition = "Content-Disposition"
  static let contentEncoding = "Content-Encoding"
  static let contentLength = "Content-Length"
  static let contentType = "Content-Type"
  static let date = "Date"
  static let userAgent = "User-Agent"
  static let userAuthorization = "User-Authorization"
  static let xAPIKey = "x-api-key"
}
