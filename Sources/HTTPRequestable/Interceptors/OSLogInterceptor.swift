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
  let logger: OSLog = .init(category: "OSLogInterceptor")
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
  public func intercept(for request: HTTPRequest, next: Next, delegate: (any URLSessionTaskDelegate)?) async throws -> HTTPAnyResponse {
    let response = try await next(request, delegate)
    os_log(logType, log: logger, "%{private}@", response.response.debugDescription)
    if let data = response.data {
      os_log(logType, log: logger, "\n%{private}@", String(data: data, encoding: .utf8) ?? "nil")
    }
    if let url = response.fileURL {
      os_log(logType, log: logger, "\n%{private}@", url.absoluteString)
    }
    return response
  }
}
