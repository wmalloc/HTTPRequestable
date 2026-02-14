//
//  URLResponse+HTTPResponse.swift
//
//
//  Created by Waqar Malik on 3/9/24.
//

import Foundation
import HTTPTypes
import HTTPTypesFoundation

/*
 # URLResponse+HTTPResponse

 This extension adds computed properties to `URLResponse` for working with HTTP responses.
 It provides utilities to convert a `URLResponse` to `HTTPResponse` or `HTTPURLResponse` safely.
 */

public extension URLResponse {
  /// Converts the `URLResponse` to an `HTTPResponse`.
  ///
  /// - Throws: `HTTPError.cannotConvertToHTTPResponse` if the conversion fails.
  /// - Returns: An `HTTPResponse` instance.
  var httpResponse: HTTPResponse {
    get throws {
      guard let httpResponse = try httpURLResponse.httpResponse else {
        throw HTTPError.cannotConvertToHTTPResponse
      }
      return httpResponse
    }
  }

  /// Converts the `URLResponse` to an `HTTPURLResponse`.
  ///
  /// - Throws: `HTTPError.cannotConvertToHTTPURLResponse` if the conversion fails.
  /// - Returns: An `HTTPURLResponse` instance.
  var httpURLResponse: HTTPURLResponse {
    get throws {
      guard let httpResponse = self as? HTTPURLResponse else {
        throw HTTPError.cannotConvertToHTTPURLResponse
      }
      return httpResponse
    }
  }
}
