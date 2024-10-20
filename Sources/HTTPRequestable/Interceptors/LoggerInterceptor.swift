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
}

extension LoggerInterceptor: ResponseInterceptor {
  public func intercept(request: HTTPRequest, data: Data?, url: URL?, response: HTTPTypes.HTTPResponse) async throws {
    logger.log(level: logLevel, "\(response.debugDescription, privacy: .private)")
    if let data {
      logger.log(level: logLevel, "\n\(String(decoding: data, as: UTF8.self), privacy: .private)")
    }
    if let url {
      logger.log(level: logLevel, "\n\(url.absoluteString, privacy: .private)")
    }
  }
}
