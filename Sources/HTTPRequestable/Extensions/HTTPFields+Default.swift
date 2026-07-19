//
//  HTTPFields+Default.swift
//
//  Created by Waqar Malik on 1/15/23.
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
#endif
import HTTPTypes

/// Extension providing a static property for default headers.
public extension HTTPFields {
  /// A static property that provides a set of common default headers.
  /// - Returns: An `HTTPFields` instance containing the default headers.
  static var defaultHeaders: HTTPFields {
    HTTPFields([.defaultAcceptEncoding, .defaultAcceptLanguage, .defaultUserAgent])
  }
}
