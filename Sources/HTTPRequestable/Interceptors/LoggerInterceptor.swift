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
  public func intercept(_ request: inout HTTPRequest, for session: URLSession) async throws {
    let debugDescription = request.debugDescription
    logger.log(level: logLevel, "\(debugDescription, privacy: .private)")
  }

  public func intercept(_ request: inout URLRequest, for session: URLSession) async throws {
    let debugDescription = request.debugDescription
    logger.log(level: logLevel, "\(debugDescription, privacy: .private)")
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
