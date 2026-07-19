//
//  RetryPolicy.swift
//
//  Created by Waqar Malik on 4/25/26.
//

#if canImport(FoundationNetworking)
public import FoundationNetworking
#else
public import Foundation
#endif

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

  /// default init
  public init(maxRetries: Int = 3, initialDelay: TimeInterval = 1, multiplier: Double = 2) {
    self.maxRetries = maxRetries
    self.initialDelay = initialDelay
    self.multiplier = multiplier
  }

  /// Function that checks if we should retry the call again
  public func shouldRetry(error: Error, attempt: Int) -> Bool {
    guard attempt < maxRetries else { return false }
    return (error as? URLError) != nil
  }

  /// The delay value for next retry call
  @inlinable
  public func delay(for attempt: Int) -> TimeInterval {
    initialDelay * pow(multiplier, Double(attempt))
  }

  /// Default retry configuration
  static var `default`: RetryPolicy {
    .init()
  }
}
