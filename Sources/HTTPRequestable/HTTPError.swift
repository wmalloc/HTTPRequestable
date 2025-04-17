//
//  HTTPError.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 1/24/25.
//

import Foundation

/// An enumeration representing different HTTP-related errors that may occur.
public enum HTTPError: LocalizedError {
  /// Thrown when an invalid URL is provided.
  case invalidURL

  /// Thrown when a URLRequest cannot be created from the given URL.
  case cannotCreateURLRequest

  /// Thrown when data cannot be converted to an HTTP response.
  case cannotConvertToHTTPResponse

  /// Thrown when data cannot be converted to an HTTPURLResponse.
  case cannotConvertToHTTPURLResponse

  /// Thrown when the content type is missing in the HTTP response headers.
  case contentTypeHeaderMissing

  /// Thrown when the specified content type is invalid or does not match expected format.
  case invalidContentType

  public var errorDescription: String? {
    description
  }
}

extension HTTPError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .invalidURL:
      String(localized: "error_invalid_url", bundle: .module)

    case .cannotCreateURLRequest:
      String(localized: "error_cant_create_url_request", bundle: .module)

    case .cannotConvertToHTTPResponse:
      String(localized: "error_cant_convert_to_http_response", bundle: .module)

    case .cannotConvertToHTTPURLResponse:
      String(localized: "error_cant_convert_to_http_url_response", bundle: .module)

    case .contentTypeHeaderMissing:
      String(localized: "error_content_type_header_missing", bundle: .module)

    case .invalidContentType:
      String(localized: "error_invalid_content_type", bundle: .module)
    }
  }
}
