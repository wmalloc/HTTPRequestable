//
//  LoggerInterceptor.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/23/24.
//

import Foundation
import HTTPTypes
import OSLog

/// A logging interceptor for HTTP requests and responses.
///
/// `LoggerInterceptor` logs details about HTTP requests and responses at a specified log level to the system logger.
/// It can be used as both an `HTTPRequestModifier` to log outgoing requests, and as an `HTTPInterceptor` to log incoming responses.
///
/// Usage:
/// - As an `HTTPRequestModifier`, it logs the request's debug description before the request is sent.
/// - As an `HTTPInterceptor`, it logs the response's debug description, payload data (if any), and file URL (if any) after receiving a response.
///
/// The log output is privacy protected using `.private` to avoid leaking sensitive information.
///
/// - Note: The logger uses the OSLog subsystem with a category of "LoggerInterceptor".
///
/// - Parameters:
///   - logLevel: The minimum severity level for log messages (default: `.default`).
///
/// Example:
/// ```swift
/// let interceptor = LoggerInterceptor(logLevel: .debug)
/// ```
@frozen
public struct LoggerInterceptor {
  public let logger: Logger = .init(category: "LoggerInterceptor")
  public let logLevel: OSLogType

  public init(logLevel: OSLogType = .default) {
    self.logLevel = logLevel
  }
}

extension LoggerInterceptor: HTTPRequestModifier {
  public func modify(_ request: inout HTTPRequest, for session: URLSession) async throws {
    let debugDescription = request.debugDescription
    logger.log(level: logLevel, "\(debugDescription, privacy: .private)")
  }
}

extension LoggerInterceptor: HTTPInterceptor {
  public func log(request: HTTPRequest, data: Data? = nil) {
    logger.log(level: logLevel, "\(request.debugDescription, privacy: .private)")
    if let data {
      logger.log(level: logLevel, "\n\(String(data: data, encoding: .utf8) ?? "nil", privacy: .private)")
    }
  }

  public func log(response: HTTPResponse, data: Data? = nil, fileURL: URL? = nil) {
    logger.log(level: logLevel, "\(response.debugDescription, privacy: .private)")
    if let data {
      logger.log(level: logLevel, "\n\(String(data: data, encoding: .utf8) ?? "nil", privacy: .private)")
    }
    if let fileURL {
      logger.log(level: logLevel, "\n\(fileURL.absoluteString, privacy: .private)")
    }
  }

  public func intercept(for request: HTTPRequest, next: Next, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPAnyResponse {
    let response = try await next(request, delegate)
    log(request: request, data: nil)
    log(response: response.response, data: response.data, fileURL: response.fileURL)
    return response
  }
}
