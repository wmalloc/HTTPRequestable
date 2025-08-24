//
//  OSLogInterceptor.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/21/24.
//

import Foundation
import HTTPTypes
import OSLog

/// `OSLogInterceptor` is a utility for intercepting and logging HTTP requests and responses using Apple's unified logging system (`OSLog`).
///
/// This structure enables detailed and configurable logging for HTTP traffic, which can be helpful for debugging, auditing, or monitoring network activity
/// in your application. It implements both `HTTPRequestModifier` and `HTTPInterceptor` protocols, allowing it to log both outgoing requests and incoming responses.
///
/// - Properties:
///   - `logger`: An `OSLog` instance that identifies logs coming from `OSLogInterceptor`.
///   - `logType`: The log level to use (e.g., `.default`, `.info`, `.error`).
///
/// - Usage:
///   - As a `HTTPRequestModifier`, logs outgoing requests.
///   - As a `HTTPInterceptor`, logs the responses, including status, data (as a UTF-8 string if possible), and any file URLs.
///
/// - Note:
///   This utility is intended for use in development, debugging, or diagnostics, as logging sensitive or large payloads to the unified logging system may have privacy or performance implications.
///
@frozen
public struct OSLogInterceptor {
  public let logger: OSLog = .init(category: "OSLogInterceptor")
  public let logType: OSLogType

  public init(logType: OSLogType = .default) {
    self.logType = logType
  }
}

extension OSLogInterceptor: HTTPRequestModifier {
  public func modify(_ request: inout HTTPRequest, for session: URLSession) async throws {
    os_log(logType, log: logger, "%{private}@", request.debugDescription)
  }
}

extension OSLogInterceptor: HTTPInterceptor {
  public func log(request: HTTPRequest, data: Data? = nil) {
    os_log(logType, log: logger, "%{private}@", request.debugDescription)
    if let data {
      os_log(logType, log: logger, "\n%{private}@", String(data: data, encoding: .utf8) ?? "nil")
    }
  }

  public func log(response: HTTPResponse, data: Data? = nil, fileURL: URL? = nil, error: (any Error)? = nil) {
    Self.log(logger, logType: logType, response: response, data: data, fileURL: fileURL, error: error)
  }

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

  public func intercept(for request: HTTPRequest, next: Next, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPAnyResponse {
    let response = try await next(request, delegate)
    log(request: request, data: nil)
    log(response: response.response, data: response.data, fileURL: response.fileURL, error: response.error)
    return response
  }
}
