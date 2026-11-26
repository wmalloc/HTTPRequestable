//
//  RetryPolicyValidationTests.swift
//
//  Created by Waqar Malik on 11/25/26.
//

import Foundation
@testable import HTTPRequestable
import HTTPTypes
import MockURLProtocol
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A seeded generator (SplitMix64), so jittered delays can be checked repeatably.
private struct SeededGenerator: RandomNumberGenerator {
  var state: UInt64

  mutating func next() -> UInt64 {
    state &+= 0x9E3779B97F4A7C15
    var value = state
    value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
    value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
    return value ^ (value >> 31)
  }
}

struct RetryPolicyConfigurationTests {
  @Test("The default policy is public and uses the documented values")
  func defaultPolicy() {
    let policy = RetryPolicy.default
    #expect(policy.maxRetries == 3)
    #expect(policy.initialDelay == 1)
    #expect(policy.multiplier == 2)
    #expect(policy.maxDelay == 60)
    #expect(!policy.retriesNonIdempotentRequests)
    #expect(policy.jitter)
    #expect(policy.retryableStatuses == [.tooManyRequests, .serviceUnavailable])
  }

  @Test("Delays are capped at longestDelay, which Task.sleep can represent")
  func longestDelay() {
    let policy = RetryPolicy(maxRetries: 10000, multiplier: 10, maxDelay: .greatestFiniteMagnitude)
    #expect(policy.delay(for: 5000) == RetryPolicy.longestDelay)
    #expect(Duration.seconds(RetryPolicy.longestDelay) > .zero)
  }

  #if os(macOS) || os(Linux)
  @Test("Invalid configuration stops the process")
  func invalidConfigurationTraps() async {
    await #expect(processExitsWith: .failure) { _ = RetryPolicy(maxRetries: -1) }
    await #expect(processExitsWith: .failure) { _ = RetryPolicy(initialDelay: -1) }
    await #expect(processExitsWith: .failure) { _ = RetryPolicy(initialDelay: 0) }
    await #expect(processExitsWith: .failure) { _ = RetryPolicy(initialDelay: .nan) }
    await #expect(processExitsWith: .failure) { _ = RetryPolicy(initialDelay: .infinity) }
    await #expect(processExitsWith: .failure) { _ = RetryPolicy(multiplier: -2) }
    await #expect(processExitsWith: .failure) { _ = RetryPolicy(multiplier: .nan) }
    await #expect(processExitsWith: .failure) { _ = RetryPolicy(maxDelay: -1) }
    await #expect(processExitsWith: .failure) { _ = RetryPolicy(maxDelay: 0) }
    await #expect(processExitsWith: .failure) { _ = RetryPolicy(maxDelay: .infinity) }
    await #expect(processExitsWith: .failure) { _ = RetryPolicy(maxDelay: .nan) }
  }
  #endif

  @Test("Jitter picks a delay between half the backoff delay and all of it")
  func jitter() {
    var generator = SeededGenerator(state: 42)
    let policy = RetryPolicy(maxRetries: 5, initialDelay: 1, multiplier: 2, maxDelay: 10)
    for attempt in 0 ..< 5 {
      let backoff = policy.delay(for: attempt)
      let delays = (0 ..< 50).map { _ in policy.retryDelay(for: attempt, using: &generator) }
      #expect(delays.allSatisfy { (backoff / 2 ... backoff).contains($0) })
      #expect(Set(delays).count > 1)
    }
  }

  @Test("Every wait is more than zero", arguments: [true, false])
  func alwaysPositive(jitter: Bool) {
    var generator = SeededGenerator(state: 7)
    let policies = [
      RetryPolicy(maxRetries: 100, initialDelay: .leastNonzeroMagnitude, multiplier: 1, maxDelay: 1, jitter: jitter),
      RetryPolicy(maxRetries: 100, initialDelay: 0.001, multiplier: 10, maxDelay: .leastNonzeroMagnitude, jitter: jitter),
      RetryPolicy(maxRetries: 100, initialDelay: 1, multiplier: 2, jitter: jitter),
      RetryPolicy(maxRetries: 100, initialDelay: 0.5, multiplier: 0, jitter: jitter),
      RetryPolicy(maxRetries: 100, initialDelay: .leastNonzeroMagnitude, multiplier: 0.5, jitter: jitter)
    ]
    for policy in policies {
      for attempt in [-5, 0, 1, 10, 99] {
        #expect(policy.delay(for: attempt) > 0)
        #expect(policy.retryDelay(for: attempt, using: &generator) > 0)
        var response = HTTPResponse(status: .serviceUnavailable)
        response.headerFields[.retryAfter] = "0"
        let afterResponse = policy.retryDelay(after: response, attempt: Swift.max(attempt, 0), now: Date(), using: &generator)
        #expect(afterResponse.map { $0 > 0 } ?? true)
      }
    }
  }

  @Test("Without jitter the backoff delay is used as it is")
  func noJitter() {
    var generator = SeededGenerator(state: 42)
    let policy = RetryPolicy(initialDelay: 1, multiplier: 2, jitter: false)
    #expect((0 ..< 4).map { policy.retryDelay(for: $0, using: &generator) } == [1, 2, 4, 8])
  }

  @Test("Retryable statuses are retried until the retries are used up")
  func statuses() {
    let policy = RetryPolicy(maxRetries: 2)
    #expect(policy.shouldRetry(status: .serviceUnavailable, attempt: 0))
    #expect(policy.shouldRetry(status: .tooManyRequests, attempt: 1))
    #expect(!policy.shouldRetry(status: .tooManyRequests, attempt: 2))
    #expect(!policy.shouldRetry(status: .internalServerError, attempt: 0))
    #expect(!policy.shouldRetry(status: .ok, attempt: 0))
    #expect(!RetryPolicy(retryableStatuses: []).shouldRetry(status: .serviceUnavailable, attempt: 0))
    #expect(RetryPolicy(retryableStatuses: [.badGateway]).shouldRetry(status: .badGateway, attempt: 0))
  }
}

struct RetryAfterTests {
  private let now = Date(timeIntervalSince1970: 784111777) // Sun, 06 Nov 1994 08:49:37 GMT

  @Test("Retry-After in seconds", arguments: [("120", 120.0), (" 5 ", 5), ("0", 0)])
  func seconds(value: String, expected: TimeInterval) {
    #expect(RetryPolicy.retryAfterDelay(value, now: now) == expected)
  }

  @Test("Retry-After as an HTTP date in any of the three formats", arguments: [
    "Sun, 06 Nov 1994 08:50:37 GMT", "Sunday, 06-Nov-94 08:50:37 GMT", "Sun Nov  6 08:50:37 1994",
  ])
  func dates(value: String) {
    #expect(RetryPolicy.retryAfterDelay(value, now: now) == 60)
  }

  @Test("A Retry-After date in the past means no delay")
  func pastDate() {
    #expect(RetryPolicy.retryAfterDelay("Sun, 06 Nov 1994 08:00:00 GMT", now: now) == 0)
  }

  @Test("Invalid Retry-After values are ignored", arguments: ["", "-1", "1.5", "abc", "5 seconds", "06 Nov 1994"])
  func invalid(value: String) {
    #expect(RetryPolicy.retryAfterDelay(value, now: now) == nil)
  }

  @Test("A Retry-After too long for an Int is a very long delay")
  func hugeSeconds() {
    #expect(RetryPolicy.retryAfterDelay(String(repeating: "9", count: 400), now: now) == .infinity)
  }

  @Test("Retry-After lengthens the backoff delay for a retryable response, up to maxDelay")
  func retryDelayAfterResponse() {
    var generator = SeededGenerator(state: 1)
    let policy = RetryPolicy(maxRetries: 2, initialDelay: 1, maxDelay: 30, jitter: false)
    func delay(_ status: HTTPResponse.Status, retryAfter: String? = nil, attempt: Int = 0) -> TimeInterval? {
      var response = HTTPResponse(status: status)
      response.headerFields[.retryAfter] = retryAfter
      return policy.retryDelay(after: response, attempt: attempt, now: now, using: &generator)
    }
    #expect(delay(.serviceUnavailable, retryAfter: "5") == 5)
    #expect(delay(.serviceUnavailable, retryAfter: "0") == 1)
    #expect(delay(.serviceUnavailable, retryAfter: "Sun, 06 Nov 1994 08:00:00 GMT") == 1)
    #expect(delay(.serviceUnavailable, retryAfter: "1", attempt: 1) == 2)
    #expect(delay(.serviceUnavailable, retryAfter: "Sun, 06 Nov 1994 08:50:07 GMT") == 30)
    #expect(delay(.tooManyRequests, retryAfter: "31") == nil)
    #expect(delay(.tooManyRequests, retryAfter: "soon") == 1)
    #expect(delay(.serviceUnavailable, attempt: 1) == 2)
    #expect(delay(.serviceUnavailable, attempt: 2) == nil)
    #expect(delay(.ok, retryAfter: "5") == nil)
  }
}

/// Counts requests across handler calls.
private actor RequestCounter {
  private(set) var count = 0

  func increment() {
    count += 1
  }
}

struct RetryLoopTests {
  private let session: URLSession = {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: configuration)
  }()

  private let fastPolicy = RetryPolicy(maxRetries: 2, initialDelay: 0.001, maxDelay: 0.01, jitter: false)

  /// Stubs `url` to answer with `statuses` in turn, one per request. Each handler registers the next,
  /// because `MockURLProtocol` removes a handler once it has answered.
  private func stub(_ url: URL, statuses: [Int], headers: [String: String] = [:], counter: RequestCounter) async throws {
    guard let status = statuses.first else { return }
    let remaining = Array(statuses.dropFirst())
    try await MockURLProtocol.setRequestHandler({ _ in
      await counter.increment()
      try await stub(url, statuses: remaining, headers: headers, counter: counter)
      let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers)!
      return (Data("\(status)".utf8), response)
    }, forIdentifier: url)
  }

  private func uniqueURL() throws -> URL {
    try #require(URL(string: "https://api.example.com/retry/\(UUID().uuidString)"))
  }

  @Test("A 503 is retried and the later success is returned")
  func retriesServiceUnavailable() async throws {
    let url = try uniqueURL()
    let counter = RequestCounter()
    try await stub(url, statuses: [503, 200], counter: counter)
    let response = try await session.performRequest(HTTPRequest(method: .get, url: url), retryPolicy: fastPolicy)
    #expect(response.response.status == .ok)
    #expect(await counter.count == 2)
  }

  @Test("Retry-After of zero still waits the backoff delay")
  func retryAfterZero() async throws {
    let url = try uniqueURL()
    let counter = RequestCounter()
    try await stub(url, statuses: [429, 200], headers: ["Retry-After": "0"], counter: counter)
    let response = try await session.performRequest(HTTPRequest(method: .get, url: url), retryPolicy: fastPolicy)
    #expect(response.response.status == .ok)
    #expect(await counter.count == 2)
  }

  @Test("When the retries are used up the last response is returned")
  func returnsLastResponse() async throws {
    let url = try uniqueURL()
    let counter = RequestCounter()
    try await stub(url, statuses: [503, 503, 503], counter: counter)
    let response = try await session.performRequest(HTTPRequest(method: .get, url: url), retryPolicy: fastPolicy)
    #expect(response.response.status == .serviceUnavailable)
    #expect(await counter.count == 3)
  }

  @Test("Non-idempotent requests and other statuses are not retried")
  func noRetry() async throws {
    let postURL = try uniqueURL()
    let postCounter = RequestCounter()
    try await stub(postURL, statuses: [503, 200], counter: postCounter)
    let post = try await session.performRequest(HTTPRequest(method: .post, url: postURL), httpBody: Data("x".utf8),
                                                retryPolicy: fastPolicy)
    #expect(post.response.status == .serviceUnavailable)
    #expect(await postCounter.count == 1)

    let errorURL = try uniqueURL()
    let errorCounter = RequestCounter()
    try await stub(errorURL, statuses: [500, 200], counter: errorCounter)
    let error = try await session.performRequest(HTTPRequest(method: .get, url: errorURL), retryPolicy: fastPolicy)
    #expect(error.response.status == .internalServerError)
    #expect(await errorCounter.count == 1)
  }

  @Test("A Retry-After longer than maxDelay ends the retries")
  func longRetryAfter() async throws {
    let url = try uniqueURL()
    let counter = RequestCounter()
    try await stub(url, statuses: [503, 200], headers: ["Retry-After": "3600"], counter: counter)
    let response = try await session.performRequest(HTTPRequest(method: .get, url: url), retryPolicy: fastPolicy)
    #expect(response.response.status == .serviceUnavailable)
    #expect(await counter.count == 1)
  }
}
