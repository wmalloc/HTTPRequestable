//
//  HTTPContentType.swift
//
//  Created by Waqar Malik on 4/27/23.
//

import Foundation

public typealias HTTPContentType = String

public extension HTTPContentType {
  static let css = "text/css"
  static let formEncoded = "application/x-www-form-urlencoded"
  static let gif = "image/gif"
  static let html = "text/html"
  static let jpeg = "image/jpeg"
  static let json = "application/json"
  static let jsonUTF8 = "application/json; charset=utf-8"
  static let octetStream = "application/octet-stream"
  static let patchjson = "application/json-patch+json"
  static let png = "image/png"
  static let svg = "image/svg+xml"
  static let textPlain = "text/plain"
  static let xml = "application/xml"
}
