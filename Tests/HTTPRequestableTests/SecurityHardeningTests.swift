//
//  SecurityHardeningTests.swift
//

import Foundation
import HTTPTypes
@testable import HTTPRequestable
import Testing

struct SecurityHardeningTests {
  @Test("Retry delay is capped and never traps")
  func retryDelayIsBounded() {
    let policy = RetryPolicy(maxRetries: 1000, initialDelay: 1, multiplier: 10, maxDelay: 30)
    #expect(policy.delay(for: 0) == 1)
    #expect(policy.delay(for: 5) == 30)
    #expect(policy.delay(for: 999) == 30)
    #expect(RetryPolicy(initialDelay: -5).delay(for: 1) == 0)
  }

  @Test("Only transient URL errors are retried")
  func retryOnlyTransientErrors() {
    let policy = RetryPolicy()
    #expect(policy.shouldRetry(error: URLError(.timedOut), attempt: 0))
    #expect(!policy.shouldRetry(error: URLError(.cancelled), attempt: 0))
    #expect(!policy.shouldRetry(error: URLError(.serverCertificateUntrusted), attempt: 0))
    #expect(!policy.shouldRetry(error: URLError(.timedOut), attempt: 3))
  }

  @Test("Non-idempotent methods are retried only when opted in")
  func retryIdempotency() {
    #expect(RetryPolicy().allowsRetry(for: .get))
    #expect(!RetryPolicy().allowsRetry(for: .post))
    #expect(RetryPolicy(retriesNonIdempotentRequests: true).allowsRetry(for: .post))
  }

  @Test("Authority with a port is split into host and port")
  func environmentAuthority() {
    let environment = HTTPEnvironment(authority: "api.example.com:8443")
    #expect(environment.host == "api.example.com")
    #expect(environment.port == 8443)
    #expect(HTTPEnvironment(authority: "api.example.com").port == nil)
  }

  @Test("Authority carrying user info is not treated as a host")
  func environmentRejectsUserInfo() {
    let environment = HTTPEnvironment(authority: "good.com@evil.com")
    #expect(environment.user == nil)
    #expect(environment.host != "evil.com")
  }

  @Test("A body stream longer than declared is rejected")
  func oversizedStreamRejected() {
    let form = MultipartForm(boundary: "B")
    let data = Data(repeating: 1, count: 100)
    form.append(stream: InputStream(data: data), withLength: 10, headers: [])
    #expect(throws: MultipartFormError.self) {
      try form.data(streamBufferSize: 16)
    }
  }
}
