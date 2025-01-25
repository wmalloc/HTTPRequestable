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
  public var logType: OSLogType

  public init(logType: OSLogType = .default) {
    self.logType = logType
  }
}

extension OSLogInterceptor: HTTPRequestInterceptor {
  public func intercept(_ request: inout HTTPRequest, for session: URLSession) async throws {
    os_log(logType, log: logger, "%{private}@", request.debugDescription)
  }
}

extension OSLogInterceptor: HTTPResponseInterceptor {
  public func intercept(_ response: inout HTTPAnyResponse, for session: URLSession) async throws {
    os_log(logType, log: logger, "%{private}@", response.response.debugDescription)
    if let data = response.data {
      os_log(logType, log: logger, "\n%{private}@", String(decoding: data, as: UTF8.self))
    }
    if let url = response.fileURL {
      os_log(logType, log: logger, "\n%{private}@", url.absoluteString)
    }
  }
}
