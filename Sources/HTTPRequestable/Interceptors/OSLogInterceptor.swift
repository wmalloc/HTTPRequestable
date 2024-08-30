//
//  OSLogInterceptor.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/21/24.
//

import Foundation
import HTTPTypes
import OSLog

public final class OSLogInterceptor {
  public var logger: OSLog = .default
  public var logType: OSLogType = .default

  public init() {}
}

extension OSLogInterceptor: RequestInterceptor {
  public func intercept(_ request: HTTPRequest) async throws -> HTTPRequest {
    os_log(logType, log: logger, "%{private}@", request.debugDescription)
    return request
  }

  public func intercept(_ request: URLRequest) async throws -> URLRequest {
    os_log(logType, log: logger, "%{private}@", request.description)
    return request
  }
}

extension OSLogInterceptor: ResponseInterceptor {
  public func intercept(data: Data, response: HTTPResponse) async throws {
    os_log(logType, log: logger, "%{private}@\n%{private}@", response.debugDescription, String(decoding: data, as: UTF8.self))
  }

  public func intercept(data: Data, response: HTTPURLResponse) async throws {
    os_log(logType, log: logger, "%{private}@\n%{private}@", response.debugDescription, String(decoding: data, as: UTF8.self))
  }
}
