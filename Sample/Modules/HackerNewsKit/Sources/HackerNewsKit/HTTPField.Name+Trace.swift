//
//  HTTPField.Name+Trace.swift
//
//  Created by Waqar Malik on 4/25/26.
//

import HTTPRequestable
import HTTPTypes

extension HTTPField.Name {
  /// X-Request-Id
  static var xRequestId: HTTPField.Name {
    #HTTPFieldName("X-Request-Id")
  }

  /// X-Correlation-Id
  static var xCorrelationId: HTTPField.Name {
    #HTTPFieldName("X-Correlation-Id")
  }

  /// X-Trace-Id
  static var xTraceId: HTTPField.Name {
    #HTTPFieldName("X-Trace-Id")
  }
}
