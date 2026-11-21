//
//  RetryPolicy.swift
//
//  Created by Waqar Malik on 4/25/26.
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
#endif
import HTTPTypes

/**
 Structure that defines retry policy to be used by
 */
@frozen
public struct RetryPolicy {
  /// Maximum number of tries
  public let maxRetries: Int

  /// intial delay for first retry
  public let initialDelay: TimeInterval

  /// Multiplier for exponential backoff delay
  public let multiplier: Double

  /// Upper bound for a single delay, so exponential backoff cannot grow without limit.
  public let maxDelay: TimeInterval

  /// Whether requests whose method is not idempotent (for example `POST`) are retried. Defaults to
  /// `false`, because retrying after a lost response can repeat a side effect on the server.
  public let retriesNonIdempotentRequests: Bool

  /// default init
  public init(maxRetries: Int = 3, initialDelay: TimeInterval = 1, multiplier: Double = 2,
              maxDelay: TimeInterval = 60, retriesNonIdempotentRequests: Bool = false) {
    self.maxRetries = maxRetries
    self.initialDelay = initialDelay
    self.multiplier = multiplier
    self.maxDelay = maxDelay
    self.retriesNonIdempotentRequests = retriesNonIdempotentRequests
  }

  /// Function that checks if we should retry the call again.
  ///
  /// Only transient network failures are retried. Cancellation and TLS or certificate failures are
  /// never retried.
  public func shouldRetry(error: Error, attempt: Int) -> Bool {
    guard attempt < maxRetries, let urlError = error as? URLError else { return false }
    return Self.transientErrorCodes.contains(urlError.code)
  }

  /// Whether a request with `method` may be retried under this policy.
  public func allowsRetry(for method: HTTPRequest.Method) -> Bool {
    retriesNonIdempotentRequests || Self.idempotentMethods.contains(method)
  }

  /// The delay value for next retry call, between zero and `maxDelay`.
  @inlinable
  public func delay(for attempt: Int) -> TimeInterval {
    let delay = initialDelay * pow(multiplier, Double(attempt))
    guard delay.isFinite else { return Swift.max(maxDelay, 0).isFinite ? Swift.max(maxDelay, 0) : 0 }
    return Swift.min(Swift.max(delay, 0), Swift.max(maxDelay, 0))
  }

  static let transientErrorCodes: Set<URLError.Code> = [
    .timedOut, .cannotFindHost, .cannotConnectToHost, .networkConnectionLost, .dnsLookupFailed,
    .notConnectedToInternet, .internationalRoamingOff, .callIsActive, .dataNotAllowed
  ]

  static let idempotentMethods: Set<HTTPRequest.Method> = [.get, .head, .put, .delete, .options, .trace]

  /// Default retry configuration
  static var `default`: RetryPolicy {
    .init()
  }
}
