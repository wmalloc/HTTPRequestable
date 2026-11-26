//
//  TransferableDefaultsTests.swift
//
//  Created by Waqar Malik on 11/25/26.
//

import Foundation
import HTTPRequestable
import Testing

/// A client that leaves out every requirement with a default. It is declared outside HTTPRequestable
/// and imports it without `@testable`, so it only compiles when the defaults are public.
private final class MinimalClient: HTTPTransferable, Sendable {
  let session = URLSession(configuration: .ephemeral)
  let requestModifiers: [any HTTPRequestModifier] = []
  let interceptors: [any HTTPInterceptor] = []
}

@Suite("HTTPTransferable defaults")
struct TransferableDefaultsTests {
  @Test("Clients in other modules get the default retry policy of no retries")
  func defaultRetryPolicy() {
    #expect(MinimalClient().retryPolicy == nil)
  }

  @Test("The default RetryPolicy is public")
  func publicDefaultPolicy() {
    #expect(RetryPolicy.default.maxRetries == 3)
  }
}
