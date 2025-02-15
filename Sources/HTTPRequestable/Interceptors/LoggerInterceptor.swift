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
  public var logLevel: OSLogType

  public init(logLevel: OSLogType = .default) {
    self.logLevel = logLevel
  }
}

extension LoggerInterceptor: HTTPRequestInterceptor {
  public func intercept(_ request: inout HTTPRequest, for session: URLSession) async throws {
    let debugDescription = request.debugDescription
    logger.log(level: logLevel, "\(debugDescription, privacy: .private)")
  }
}

extension LoggerInterceptor: HTTPResponseInterceptor {
  public func intercept(_ response: inout HTTPAnyResponse, for session: URLSession) async throws {
    let httpResponse = response.response
    logger.log(level: logLevel, "\(httpResponse.debugDescription, privacy: .private)")
    if let data = response.data {
      logger.log(level: logLevel, "\n\(String(decoding: data, as: UTF8.self), privacy: .private)")
    }
    if let url = response.fileURL {
      logger.log(level: logLevel, "\n\(url.absoluteString, privacy: .private)")
    }
  }
}
