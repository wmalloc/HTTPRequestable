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
  let logger: Logger = .init(category: "LoggerInterceptor")
  public var logLevel: OSLogType = .default

  public init() {}
}

extension LoggerInterceptor: RequestInterceptor {
  public func intercept(_ request: HTTPRequest, for session: URLSession) async throws -> HTTPRequest {
    logger.log(level: logLevel, "\(request.debugDescription, privacy: .private)")
    return request
  }

  public func intercept(_ request: URLRequest, for session: URLSession) async throws -> URLRequest {
    logger.log(level: logLevel, "\(request.debugDescription, privacy: .private)")
    return request
  }
}

extension LoggerInterceptor: ResponseInterceptor {
  public func intercept(data: Data, response: HTTPResponse) async throws {
    logger.log(level: logLevel, "\(response.debugDescription, privacy: .private)\n\(String(decoding: data, as: UTF8.self), privacy: .private)")
  }

  public func intercept(data: Data, response: HTTPURLResponse) async throws {
    logger.log(level: logLevel, "\(response.debugDescription, privacy: .private)\n\(String(decoding: data, as: UTF8.self), privacy: .private)")
  }
}
