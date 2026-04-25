//
//  RetryPolicyTests.swift
//
//  Created by Waqar Malik on 4/25/26.
//

import Foundation
@testable import HTTPRequestable
import Testing

@Suite("RetryPolicy Tests")
struct RetryPolicyTests {
  // MARK: - Initialization Tests

  @Test("Default initialization creates policy with expected values")
  func defaultInitialization() {
    let policy = RetryPolicy()

    #expect(policy.maxRetries == 3)
    #expect(policy.initialDelay == 1)
    #expect(policy.multiplier == 2)
  }

  @Test("Custom initialization sets correct values")
  func customInitialization() {
    let policy = RetryPolicy(maxRetries: 5, initialDelay: 2.0, multiplier: 1.5)

    #expect(policy.maxRetries == 5)
    #expect(policy.initialDelay == 2.0)
    #expect(policy.multiplier == 1.5)
  }

  // MARK: - Should Retry Tests

  @Test("Should retry when attempt is less than max retries with URLError")
  func shouldRetryWithURLError() {
    let policy = RetryPolicy(maxRetries: 3)
    let error = URLError(.notConnectedToInternet)

    #expect(policy.shouldRetry(error: error, attempt: 0))
    #expect(policy.shouldRetry(error: error, attempt: 1))
    #expect(policy.shouldRetry(error: error, attempt: 2))
  }

  @Test("Should not retry when attempt equals or exceeds max retries")
  func shouldNotRetryWhenMaxRetriesReached() {
    let policy = RetryPolicy(maxRetries: 3)
    let error = URLError(.timedOut)

    #expect(!policy.shouldRetry(error: error, attempt: 3))
    #expect(!policy.shouldRetry(error: error, attempt: 4))
    #expect(!policy.shouldRetry(error: error, attempt: 10))
  }

  @Test("Should not retry with non-URLError")
  func shouldNotRetryWithNonURLError() {
    let policy = RetryPolicy(maxRetries: 3)

    enum CustomError: Error {
      case someError
    }

    let error = CustomError.someError

    #expect(!policy.shouldRetry(error: error, attempt: 0))
    #expect(!policy.shouldRetry(error: error, attempt: 1))
  }

  @Test("Should retry with different URLError types", arguments: [
    URLError(.networkConnectionLost),
    URLError(.notConnectedToInternet),
    URLError(.timedOut),
    URLError(.cannotFindHost),
    URLError(.cannotConnectToHost),
    URLError(.dnsLookupFailed)
  ])
  func shouldRetryWithVariousURLErrors(error: URLError) {
    let policy = RetryPolicy(maxRetries: 3)
    #expect(policy.shouldRetry(error: error, attempt: 0))
  }

  // MARK: - Delay Calculation Tests

  @Test("Delay for first attempt is equal to initial delay")
  func delayForFirstAttempt() {
    let policy = RetryPolicy(maxRetries: 3, initialDelay: 1.0, multiplier: 2.0)
    let delay = policy.delay(for: 0)

    #expect(delay == 1.0)
  }

  @Test("Delay calculation uses exponential backoff")
  func exponentialBackoffDelay() {
    let policy = RetryPolicy(maxRetries: 5, initialDelay: 1.0, multiplier: 2.0)

    // attempt 0: 1.0 * 2^0 = 1.0
    #expect(policy.delay(for: 0) == 1.0)

    // attempt 1: 1.0 * 2^1 = 2.0
    #expect(policy.delay(for: 1) == 2.0)

    // attempt 2: 1.0 * 2^2 = 4.0
    #expect(policy.delay(for: 2) == 4.0)

    // attempt 3: 1.0 * 2^3 = 8.0
    #expect(policy.delay(for: 3) == 8.0)

    // attempt 4: 1.0 * 2^4 = 16.0
    #expect(policy.delay(for: 4) == 16.0)
  }

  @Test("Delay calculation with custom multiplier")
  func delayWithCustomMultiplier() {
    let policy = RetryPolicy(maxRetries: 3, initialDelay: 2.0, multiplier: 1.5)

    // attempt 0: 2.0 * 1.5^0 = 2.0
    #expect(policy.delay(for: 0) == 2.0)

    // attempt 1: 2.0 * 1.5^1 = 3.0
    #expect(policy.delay(for: 1) == 3.0)

    // attempt 2: 2.0 * 1.5^2 = 4.5
    #expect(policy.delay(for: 2) == 4.5)
  }

  @Test("Delay calculation with custom initial delay")
  func delayWithCustomInitialDelay() {
    let policy = RetryPolicy(maxRetries: 3, initialDelay: 5.0, multiplier: 2.0)

    // attempt 0: 5.0 * 2^0 = 5.0
    #expect(policy.delay(for: 0) == 5.0)

    // attempt 1: 5.0 * 2^1 = 10.0
    #expect(policy.delay(for: 1) == 10.0)

    // attempt 2: 5.0 * 2^2 = 20.0
    #expect(policy.delay(for: 2) == 20.0)
  }

  @Test("Delay calculation with multiplier of 1 remains constant")
  func delayWithMultiplierOfOne() {
    let policy = RetryPolicy(maxRetries: 3, initialDelay: 3.0, multiplier: 1.0)

    #expect(policy.delay(for: 0) == 3.0)
    #expect(policy.delay(for: 1) == 3.0)
    #expect(policy.delay(for: 2) == 3.0)
    #expect(policy.delay(for: 5) == 3.0)
  }

  // MARK: - Edge Cases

  @Test("Policy with zero max retries never retries")
  func zeroMaxRetries() {
    let policy = RetryPolicy(maxRetries: 0)
    let error = URLError(.notConnectedToInternet)

    #expect(!policy.shouldRetry(error: error, attempt: 0))
  }

  @Test("Policy with very large max retries allows many attempts")
  func largeMaxRetries() {
    let policy = RetryPolicy(maxRetries: 100)
    let error = URLError(.timedOut)

    #expect(policy.shouldRetry(error: error, attempt: 50))
    #expect(policy.shouldRetry(error: error, attempt: 99))
    #expect(!policy.shouldRetry(error: error, attempt: 100))
  }

  @Test("Delay with zero initial delay always returns zero")
  func zeroInitialDelay() {
    let policy = RetryPolicy(maxRetries: 3, initialDelay: 0.0, multiplier: 2.0)

    #expect(policy.delay(for: 0) == 0.0)
    #expect(policy.delay(for: 1) == 0.0)
    #expect(policy.delay(for: 2) == 0.0)
  }

  @Test("Negative attempt number calculates delay correctly")
  func negativeAttempt() {
    let policy = RetryPolicy(maxRetries: 3, initialDelay: 2.0, multiplier: 2.0)

    // 2.0 * 2^(-1) = 1.0
    #expect(policy.delay(for: -1) == 1.0)
  }
}
