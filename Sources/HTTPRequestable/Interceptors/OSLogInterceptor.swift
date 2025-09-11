//
//  OSLogInterceptor.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/21/24.
//

import Foundation
import HTTPTypes
import OSLog

/**
 # OSLogInterceptor

 `OSLogInterceptor` is a utility for intercepting and logging HTTP requests and responses using Apple's unified logging system (`OSLog`).

 This structure enables detailed and configurable logging for HTTP traffic, which can be helpful for debugging, auditing, or monitoring network activity
 in your application. It implements both `HTTPRequestModifier` and `HTTPInterceptor` protocols, allowing it to log both outgoing requests and incoming responses.
 */

@frozen
public struct OSLogInterceptor {
  /// An `OSLog` instance that identifies logs coming from `OSLogInterceptor`.
  public let logger: OSLog = .init(category: "OSLogInterceptor")

  /// The log level to use (e.g., `.default`, `.info`, `.error`).
  public let logType: OSLogType

  /// Initializes a new `OSLogInterceptor` with the specified log level.
  ///
  /// - Parameter logType: The log level to use. Defaults to `.default`.
  public init(logType: OSLogType = .default) {
    self.logType = logType
  }
}

extension OSLogInterceptor: HTTPRequestModifier {
  /// Logs the debug description of the HTTP request before it is sent.
  ///
  /// - Parameters:
  ///   - request: The HTTP request to modify.
  ///   - session: The URL session associated with the request.
  public func modify(_ request: inout HTTPRequest, for session: URLSession) async throws {
    os_log(logType, log: logger, "%{private}@", request.debugDescription)
  }
}

extension OSLogInterceptor: HTTPInterceptor {
  /// Logs the HTTP request and optional data.
  ///
  /// - Parameters:
  ///   - request: The HTTP request to log.
  ///   - data: Optional data associated with the request.
  public func log(request: HTTPRequest, data: Data? = nil) {
    os_log(logType, log: logger, "%{private}@", request.debugDescription)
    if let data {
      os_log(logType, log: logger, "\n%{private}@", String(data: data, encoding: .utf8) ?? "nil")
    }
  }

  /// Logs the HTTP response and optional data, file URL, and error.
  ///
  /// - Parameters:
  ///   - response: The HTTP response to log.
  ///   - data: Optional data associated with the response.
  ///   - fileURL: Optional file URL associated with the response.
  ///   - error: Optional error associated with the response.
  public func log(response: HTTPResponse, data: Data? = nil, fileURL: URL? = nil, error: (any Error)? = nil) {
    Self.log(logger, logType: logType, response: response, data: data, fileURL: fileURL, error: error)
  }

  /// Logs the HTTP response and optional data, file URL, and error using a static method.
  ///
  /// - Parameters:
  ///   - logger: The logger instance to use for logging.
  ///   - logType: The log level to use.
  ///   - response: The HTTP response to log.
  ///   - data: Optional data associated with the response.
  ///   - fileURL: Optional file URL associated with the response.
  ///   - error: Optional error associated with the response.
  public static func log(_ logger: OSLog, logType: OSLogType, response: HTTPResponse, data: Data? = nil, fileURL: URL? = nil, error: (any Error)? = nil) {
    os_log(logType, log: logger, "%{private}@", response.debugDescription)
    if let data {
      os_log(logType, log: logger, "\n%{private}@", String(data: data, encoding: .utf8) ?? "nil")
    }
    if let fileURL {
      os_log(logType, log: logger, "\n%{private}@", fileURL.absoluteString)
    }
    if let error {
      os_log(logType, log: logger, "\n%{private}@", "\(error)")
    }
  }

  /// Intercepts the HTTP request and logs the request and response details.
  ///
  /// - Parameters:
  ///   - request: The HTTP request to intercept.
  ///   - next: The next interceptor in the chain.
  ///   - delegate: An optional URL session task delegate.
  /// - Returns: The intercepted HTTP response.
  public func intercept(for request: HTTPRequest, next: Next, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPAnyResponse {
    let response = try await next(request, delegate)
    log(request: request, data: nil)
    log(response: response.response, data: response.data, fileURL: response.fileURL, error: response.error)
    return response
  }
}
