//
//  HTTPField.Name+Trace.swift
//
//  Created by Waqar Malik on 4/25/26.
//

import Foundation
import HTTPTypes

extension HTTPField.Name {
  /// X-Request-Id
  static var xRequestId: HTTPField.Name {
    .init("X-Request-Id")!
  }

  /// X-Correlation-Id
  static var xCorrelationId: HTTPField.Name {
    .init("X-Correlation-Id")!
  }

  /// X-Trace-Id
  static var xTraceId: HTTPField.Name {
    .init("X-Trace-Id")!
  }
}
