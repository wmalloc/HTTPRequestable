//
//  RetryPolicy.swift
//
//  Created by Waqar Malik on 4/25/26.
//

import Foundation
import HTTPTypes
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// How a request is retried after a transient failure, with exponential backoff.
///
/// A request is retried when it fails with a transient network error, such as a timeout or a lost
/// connection, or when the response status is in ``retryableStatuses`` (by default `429 Too Many
/// Requests` and `503 Service Unavailable`). Requests whose method is not idempotent, such as `POST`,
/// are not retried unless ``retriesNonIdempotentRequests`` is `true`.
///
/// Before retry `n` (counting from `0`) the request waits `initialDelay * multiplier^n` seconds, but never
/// less than ``initialDelay`` and never more than ``maxDelay``. With ``jitter``, the wait is a random time between half that delay and all of it, so
/// clients that failed together do not retry together. A `Retry-After` header on a retryable response
/// can lengthen the wait. Every wait is longer than zero.
///
/// ```swift
/// let policy = RetryPolicy(maxRetries: 3, initialDelay: 0.5, maxDelay: 10)
/// ```
public struct RetryPolicy: Sendable {
  /// The number of retries after the first attempt, so a request is sent at most `maxRetries + 1` times.
  /// `0` means no retries.
  public let maxRetries: Int

  /// The delay before the first retry, in seconds. Always more than `0`.
  public let initialDelay: TimeInterval

  /// The factor the delay grows by after each retry. The delay never falls below ``initialDelay``, so a
  /// multiplier of `1` or less, including `0`, gives a fixed delay of ``initialDelay``.
  public let multiplier: Double

  /// Upper bound for a single delay, in seconds, so exponential backoff cannot grow without limit. A
  /// `Retry-After` longer than this stops the retries instead of being shortened. Always more than `0`.
  public let maxDelay: TimeInterval

  /// Whether requests whose method is not idempotent (for example `POST`) are retried. Defaults to
  /// `false`, because retrying after a lost response can repeat a side effect on the server.
  public let retriesNonIdempotentRequests: Bool

  /// Whether each backoff delay is replaced by a random delay between half that delay and all of it
  /// ("equal jitter"), which spreads retries out while keeping every wait above zero. Defaults to `true`.
  /// A `Retry-After` delay is not randomized.
  public let jitter: Bool

  /// The response statuses that are retried. Defaults to `429 Too Many Requests` and `503 Service
  /// Unavailable`; pass an empty set to retry network errors only.
  public let retryableStatuses: Set<HTTPResponse.Status>

  /// The longest single delay, in seconds, whatever ``maxDelay`` is. `Task.sleep` cannot represent much
  /// longer durations and stops the process instead.
  public static let longestDelay: TimeInterval = 1000000000

  /// Creates a retry policy.
  ///
  /// - Parameters:
  ///   - maxRetries: The number of retries after the first attempt. Must be `0` or more.
  ///   - initialDelay: The delay before the first retry, in seconds. Must be finite and more than `0`.
  ///   - multiplier: The factor the delay grows by after each retry. Must be finite and `0` or more. The
  ///     delay never falls below `initialDelay`, so `1` or less gives a fixed delay.
  ///   - maxDelay: Upper bound for a single delay, in seconds. Must be finite and more than `0`. Delays are
  ///     also capped at ``longestDelay``.
  ///   - retriesNonIdempotentRequests: Whether requests such as `POST` are retried.
  ///   - jitter: Whether backoff delays are randomized between half the computed delay and all of it.
  ///   - retryableStatuses: The response statuses that are retried.
  /// - Precondition: The values are in the ranges above. A policy is fixed configuration, so an invalid
  ///   value is a programming error.
  public init(maxRetries: Int = 3, initialDelay: TimeInterval = 1, multiplier: Double = 2,
              maxDelay: TimeInterval = 60, retriesNonIdempotentRequests: Bool = false, jitter: Bool = true,
              retryableStatuses: Set<HTTPResponse.Status> = [.tooManyRequests, .serviceUnavailable])
  {
    precondition(maxRetries >= 0, "RetryPolicy.maxRetries must be 0 or more")
    precondition(initialDelay.isFinite && initialDelay > 0, "RetryPolicy.initialDelay must be finite and more than 0")
    precondition(multiplier.isFinite && multiplier >= 0, "RetryPolicy.multiplier must be finite and 0 or more")
    precondition(maxDelay.isFinite && maxDelay > 0, "RetryPolicy.maxDelay must be finite and more than 0")
    self.maxRetries = maxRetries
    self.initialDelay = initialDelay
    self.multiplier = multiplier
    self.maxDelay = maxDelay
    self.retriesNonIdempotentRequests = retriesNonIdempotentRequests
    self.jitter = jitter
    self.retryableStatuses = retryableStatuses
  }

  /// Whether a request that failed with `error` on retry `attempt` (counting from `0`) should be retried.
  ///
  /// Only transient network failures are retried. Cancellation and TLS or certificate failures are
  /// never retried.
  public func shouldRetry(error: Error, attempt: Int) -> Bool {
    guard attempt < maxRetries, let urlError = error as? URLError else { return false }
    return Self.transientErrorCodes.contains(urlError.code)
  }

  /// Whether a request that received `status` on retry `attempt` (counting from `0`) should be retried.
  public func shouldRetry(status: HTTPResponse.Status, attempt: Int) -> Bool {
    attempt < maxRetries && retryableStatuses.contains(status)
  }

  /// Whether a request with `method` may be retried under this policy.
  public func allowsRetry(for method: HTTPRequest.Method) -> Bool {
    retriesNonIdempotentRequests || Self.idempotentMethods.contains(method)
  }

  /// The backoff delay before retry `attempt`, without jitter: `initialDelay * multiplier^attempt`, but at
  /// least ``initialDelay`` and at most ``maxDelay`` (and ``longestDelay``). Always more than `0`; an
  /// `attempt` below `0` counts as `0`.
  @inlinable
  public func delay(for attempt: Int) -> TimeInterval {
    let limit = Swift.min(maxDelay, Self.longestDelay)
    let delay = initialDelay * pow(multiplier, Double(Swift.max(attempt, 0)))
    // pow overflows to infinity for large attempts; that is past any limit.
    guard delay.isFinite else { return limit }
    // A multiplier below 1 would shrink the delay toward zero, so initialDelay is the floor.
    return Swift.min(Swift.max(delay, initialDelay), limit)
  }

  /// The time to wait before retry `attempt` after a network error: ``delay(for:)``, or with ``jitter`` a
  /// random time between half of it and all of it. Always more than `0`.
  func retryDelay(for attempt: Int, using generator: inout some RandomNumberGenerator) -> TimeInterval {
    let delay = delay(for: attempt)
    guard jitter else { return delay }
    // Half of the smallest positive delay rounds to zero, so the delay itself is the lower bound then.
    let lowerBound = delay / 2 > 0 ? delay / 2 : delay
    return TimeInterval.random(in: lowerBound ... delay, using: &generator)
  }

  /// The time to wait before retrying `response`, or `nil` when it should not be retried: its status
  /// is not retryable, the retries are used up, or its `Retry-After` is longer than ``maxDelay``.
  ///
  /// The wait is ``retryDelay(for:using:)``, or a valid `Retry-After` when that is longer, so it is
  /// always more than `0`, even for `Retry-After: 0`.
  func retryDelay(after response: HTTPResponse, attempt: Int, now: Date,
                  using generator: inout some RandomNumberGenerator) -> TimeInterval?
  {
    guard shouldRetry(status: response.status, attempt: attempt) else { return nil }
    let backoff = retryDelay(for: attempt, using: &generator)
    guard let retryAfter = response.headerFields[.retryAfter].flatMap({ Self.retryAfterDelay($0, now: now) }) else {
      return backoff
    }
    // Retrying sooner than the server asked would likely fail again, so a longer wait than the policy
    // allows ends the retries.
    guard retryAfter <= Swift.min(maxDelay, Self.longestDelay) else { return nil }
    return Swift.max(retryAfter, backoff)
  }

  /// The delay a `Retry-After` value asks for, in seconds: either a number of seconds or an HTTP date
  /// (RFC 9110 section 10.2.3). A date in the past means no delay. `nil` when the value is neither.
  static func retryAfterDelay(_ value: String, now: Date) -> TimeInterval? {
    let value = value.trimmingCharacters(in: .whitespaces)
    if !value.isEmpty, value.allSatisfy({ $0.isASCII && $0.isNumber }) {
      // Too many digits for an Int is still a valid, very long delay.
      return TimeInterval(value) ?? .infinity
    }
    guard let date = httpDate(value) else { return nil }
    return Swift.max(date.timeIntervalSince(now), 0)
  }

  /// Parses an HTTP date in the preferred IMF-fixdate format or either obsolete format, which recipients
  /// must also accept (RFC 9110 section 5.6.7).
  static func httpDate(_ value: String) -> Date? {
    // The asctime format pads a single-digit day with a second space.
    let value = value.split(separator: " ").joined(separator: " ")
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "GMT")
    for format in ["EEE, dd MMM yyyy HH:mm:ss 'GMT'", "EEEE, dd-MMM-yy HH:mm:ss 'GMT'", "EEE MMM d HH:mm:ss yyyy"] {
      formatter.dateFormat = format
      if let date = formatter.date(from: value) {
        return date
      }
    }
    return nil
  }

  static let transientErrorCodes: Set<URLError.Code> = [
    .timedOut, .cannotFindHost, .cannotConnectToHost, .networkConnectionLost, .dnsLookupFailed,
    .notConnectedToInternet, .internationalRoamingOff, .callIsActive, .dataNotAllowed
  ]

  static let idempotentMethods: Set<HTTPRequest.Method> = [.get, .head, .put, .delete, .options, .trace]

  /// The default policy: 3 retries starting at 1 second, doubling up to 60 seconds, with jitter, for
  /// idempotent requests, on transient network errors and `429` and `503` responses.
  public static let `default` = RetryPolicy()
}
