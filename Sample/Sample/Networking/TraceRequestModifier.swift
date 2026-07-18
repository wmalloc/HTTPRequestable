//
//  TraceRequestModifier.swift
//
//  Created by Waqar Malik on 4/25/26.
//

import Foundation
import HTTPRequestable
import HTTPTypes

/// A request modifier that injects a unique trace identifier into every outgoing request.
///
/// The trace ID is generated per modification using the provided generator (defaults to `UUID().uuidString`)
/// and is attached to the request as an HTTP header (defaults to `X-Trace-Id`).
struct TraceRequestModifier {
  /// The HTTP header field to set for the trace identifier.
  let headerField: HTTPField.Name

  /// A closure that generates a new trace identifier string for each request.
  let generator: @Sendable () -> String

  /// Creates a new trace request modifier.
  /// - Parameters:
  ///   - headerField: The HTTP header field to set. Default is `"X-Trace-Id"`.
  ///   - idGenerator: A closure used to generate a trace ID per request. Default generates a UUID string.
  init(headerField: HTTPField.Name = .xTraceId, idGenerator: @escaping @Sendable () -> String = { UUID().uuidString }) {
    self.headerField = headerField
    self.generator = idGenerator
  }
}

extension TraceRequestModifier {
  /// A convenience default instance that uses the `X-Trace-Id` header and UUIDs.
  static let `default` = TraceRequestModifier()
}

extension TraceRequestModifier: HTTPRequestModifier {
  func modify(_ request: inout HTTPRequest, for session: URLSession?) async throws {
    let traceID = generator()
    request.headerFields[headerField] = traceID
  }

  func modify(_ request: inout URLRequest, for session: URLSession?) async throws {
    let traceID = generator()
    request.addValue(traceID, forHTTPField: headerField)
  }
}
