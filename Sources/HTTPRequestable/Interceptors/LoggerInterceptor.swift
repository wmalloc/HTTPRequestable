//
//  LoggerInterceptor.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/23/24.
//

import Foundation
import HTTPTypes
import OSLog

public final class LoggerInterceptor {
  /// The logger instance used for logging messages.
  public let logger: Logger = .init(subsystem: "com.waqarmalik.HTTPRequestable", category: "LoggerInterceptor")

  /// The minimum severity level for log messages.
  public let logLevel: OSLogType

  /// Initializes a new `LoggerInterceptor` with the specified log level.
  ///
  /// - Parameter logLevel: The minimum severity level for log messages. Defaults to `.default`.
  public init(logLevel: OSLogType = .default) {
    self.logLevel = logLevel
  }

  /// Logs the HTTP request and optional data.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequest` to log.
  ///   - data: Optional data associated with the request.
  public func log(request: HTTPRequest, data: Data? = nil) {
    logger.log(level: logLevel, "\(request.debugDescription, privacy: .private)")
    if let data {
      logger.log(level: logLevel, "\n\(String(data: data, encoding: .utf8) ?? "nil", privacy: .private)")
    }
  }

  /// Logs the HTTP response and optional data, file URL, and error.
  ///
  /// - Parameters:
  ///   - response: The `HTTPResponse` to log.
  ///   - data: Optional data associated with the response.
  ///   - fileURL: Optional file `URL` associated with the response.
  ///   - error: Optional error associated with the response.
  public func log(response: HTTPResponse, data: Data? = nil, fileURL: URL? = nil, error: (any Error)? = nil) {
    Self.log(logger, level: logLevel, response: response, data: data, fileURL: fileURL, error: error)
  }

  /// Logs the HTTP response and optional data, file URL, and error using a static method.
  ///
  /// - Parameters:
  ///   - logger: The logger instance to use for logging.
  ///   - level: The log level to use.
  ///   - response: The `HTTPResponse` to log.
  ///   - data: Optional data associated with the response.
  ///   - fileURL: Optional file `URL` associated with the response.
  ///   - error: Optional error associated with the response.
  public static func log(_ logger: Logger, level: OSLogType, response: HTTPResponse, data: Data? = nil, fileURL: URL? = nil, error: (any Error)? = nil) {
    logger.log(level: level, "\(response.debugDescription, privacy: .private)")
    if let data {
      logger.log(level: level, "\n\(String(data: data, encoding: .utf8) ?? "nil", privacy: .private)")
    }
    if let fileURL {
      logger.log(level: level, "\n\(fileURL.absoluteString, privacy: .private)")
    }
    if let error {
      logger.log(level: level, "\(error)")
    }
  }
}

extension LoggerInterceptor: HTTPRequestModifier {
  /// Logs the debug description of the HTTP request before it is sent.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequest` to modify.
  ///   - session: The `URLSession` associated with the request.
  public func modify(_ request: inout HTTPRequest, for session: URLSession?) async throws {
    let debugDescription = request.debugDescription
    logger.log(level: logLevel, "\(debugDescription, privacy: .private)")
  }

  public func modify(_ request: inout URLRequest, for session: URLSession?) async throws {
    let debugDescription = request.debugDescription
    logger.log(level: logLevel, "\(debugDescription, privacy: .private)")
  }
}

extension LoggerInterceptor: HTTPInterceptor {
  /// Intercepts the HTTP request and logs the request and response details.
  ///
  /// - Parameters:
  ///   - request: The `HTTPRequest` to intercept.
  ///   - next: The next interceptor in the chain.
  ///   - delegate: An optional `URL` session task delegate.
  /// - Returns: The intercepted `HTTPDataResponse`.
  public func intercept(for request: HTTPRequest, next: Next, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPDataResponse {
    let response = try await next(request, delegate)
    log(request: request, data: nil)
    log(response: response.response, data: response.data, fileURL: response.fileURL, error: response.error)
    return response
  }
}
