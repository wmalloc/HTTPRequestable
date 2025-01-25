//
//  HTTPError.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 1/24/25.
//

import Foundation

/// An enumeration representing different HTTP-related errors that may occur.
enum HTTPError: Error {
  /// Thrown when an invalid URL is provided.
  case invalidURL

  /// Thrown when a URLRequest cannot be created from the given URL.
  case cannotCreateURLRequest

  /// Thrown when data cannot be converted to an HTTP response.
  case cannotConvertToHTTPResponse

  /// Thrown when data cannot be converted to an HTTPURLResponse.
  case cannotConvertToHTTPURLResponse

  /// Thrown when the content type is missing in the HTTP response headers.
  case contentTypeMissing

  /// Thrown when the specified content type is invalid or does not match expected format.
  case invalidContentType
}
