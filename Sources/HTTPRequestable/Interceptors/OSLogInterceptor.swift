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
  public var logger: OSLog = .init(category: "OSLogInterceptor")
  public var logType: OSLogType = .default

  public init() {}
}

extension OSLogInterceptor: RequestInterceptor {
  public func intercept(_ request: inout HTTPRequest, for session: URLSession) async throws {
    os_log(logType, log: logger, "%{private}@", request.debugDescription)
  }
  
  public func intercept(_ request: inout URLRequest, for session: URLSession) async throws {
    os_log(logType, log: logger, "%{private}@", request.description)
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
