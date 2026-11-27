//
//  HTTPError.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 1/24/25.
//

import Foundation
import HTTPTypes
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// An enumeration representing different HTTP-related errors that may occur.
public enum HTTPError: LocalizedError, Sendable {
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

  /// Thrown when header value is missing
  case headerValueMissing(String)

  /// Thrown when the response status is not in the successful range.
  case unacceptableStatusCode(HTTPResponse.Status)

  public var errorDescription: String? {
    description
  }
}

extension HTTPError: CustomStringConvertible {
  public var description: String {
    switch self {
    case .invalidURL:
      Message.invalidURL

    case .cannotCreateURLRequest:
      Message.cannotCreateURLRequest

    case .cannotConvertToHTTPResponse:
      Message.cannotConvertToHTTPResponse

    case .cannotConvertToHTTPURLResponse:
      Message.cannotConvertToHTTPURLResponse

    case .contentTypeHeaderMissing:
      Message.contentTypeHeaderMissing

    case .invalidContentType:
      Message.invalidContentType

    case .headerValueMissing(let header):
      "\(Message.headerValueMissing): \(header)"

    case .unacceptableStatusCode(let status):
      "\(Message.unacceptableStatusCode) \(status.code)"
    }
  }
}

extension HTTPError {
  /// The text of each error's ``description``.
  enum Message {
    static var invalidURL: String {
      "Cannot create URL."
    }

    static var cannotCreateURLRequest: String {
      "Cannot create URLRequest."
    }

    static var cannotConvertToHTTPResponse: String {
      "Cannot convert URLResponse to HTTPResponse."
    }

    static var cannotConvertToHTTPURLResponse: String {
      "Cannot convert URLResponse to HTTPURLResponse."
    }

    static var contentTypeHeaderMissing: String {
      "ContentType header is missing."
    }

    static var invalidContentType: String {
      "ContentType header value is invalid"
    }

    static var headerValueMissing: String {
      "Header missing value"
    }

    static var unacceptableStatusCode: String {
      "Unacceptable HTTP status code:"
    }
  }
}
