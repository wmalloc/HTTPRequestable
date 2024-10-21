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
}

extension OSLogInterceptor: ResponseInterceptor {
  public func intercept(request: HTTPRequest, data: Data?, url: URL?, response: HTTPTypes.HTTPResponse) async throws {
    os_log(logType, log: logger, "%{private}@", response.debugDescription)
    if let data {
      os_log(logType, log: logger, "\n%{private}@", String(decoding: data, as: UTF8.self))
    }
    if let url {
      os_log(logType, log: logger, "\n%{private}@", url.absoluteString)
    }
  }
}
