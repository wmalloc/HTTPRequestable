//
//  OSLogInterceptor.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/21/24.
//

import Foundation
import HTTPTypes
import OSLog

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
  public func intercept(_ response: inout HTTPAnyResponse, for session: URLSession) async throws {
    os_log(logType, log: logger, "%{private}@", response.response.debugDescription)
    if let data = response.data {
      os_log(logType, log: logger, "\n%{private}@", String(data: data, encoding: .utf8) ?? "nil")
    }
    if let url = response.fileURL {
      os_log(logType, log: logger, "\n%{private}@", url.absoluteString)
    }
  }
}
