//
//  LoggerInterceptor.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/23/24.
//

import Foundation
import HTTPTypes
import OSLog

public struct LoggerInterceptor: Sendable, RequestInterceptor, ResponseInterceptor {
  public let level: OSLogType
  public let logger: Logger

  public init(logger: Logger = .init(subsystem: "HTTPRequestable", category: "LoggerInterceptor"), level: OSLogType = .default) {
    self.logger = logger
    self.level = level
  }

  public func intercept(_ request: HTTPRequest) async throws -> HTTPRequest {
    logger.log(level: level, "\(request.debugDescription, privacy: .private)")
    return request
  }

  public func intercept(_ request: URLRequest) async throws -> URLRequest {
    logger.log(level: level, "\(request.debugDescription, privacy: .private)")
    return request
  }

  public func intercept(data: Data, response: HTTPResponse) async throws {
    logger.log(level: level, "\(response.debugDescription, privacy: .private)\n\(String(decoding: data, as: UTF8.self), privacy: .private)")
  }

  public func intercept(data: Data, response: HTTPURLResponse) async throws {
    logger.log(level: level, "\(response.debugDescription, privacy: .private)\n\(String(decoding: data, as: UTF8.self), privacy: .private)")
  }
}
