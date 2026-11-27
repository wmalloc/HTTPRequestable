//
//  HackerNews.swift
//
//  Created by Waqar Malik on 9/7/24.
//

import Foundation
import HTTPRequestable

public final class HackerNews: HTTPTransferable, Sendable {
  public static let shared = HackerNews()
  public let requestModifiers: [any HTTPRequestModifier]
  public let interceptors: [any HTTPInterceptor] = []

  public let environment: HTTPEnvironment = .init(authority: "hacker-news.firebaseio.com", path: "/v0")
  public let session: URLSession

  public let retryPolicy: RetryPolicy? = RetryPolicy()

  /// The task delegate every request is sent with, or `nil` for the library's default protection
  /// (its redirect policy). Use ``init(session:pinning:)`` to pin the server's public keys.
  public let requestDelegate: (any URLSessionTaskDelegate)?

  /// Creates a client.
  /// - Parameters:
  ///   - session: The session used for all requests. Defaults to a session backed by
  ///     `URLSessionConfiguration.default`; tests inject one whose `protocolClasses` stub the network.
  ///     Its own delegate must not handle server trust challenges, or it replaces any pinning.
  ///   - requestDelegate: The task delegate every request is sent with. Defaults to `nil`.
  public init(session: URLSession = URLSession(configuration: .default, delegate: nil, delegateQueue: nil),
              requestDelegate: (any URLSessionTaskDelegate)? = nil) {
    self.session = session
    self.requestDelegate = requestDelegate
    let modifier = HTTPRequestHeadersModifier(fields: [.accept(.json), .contentType(.json)])
    let traceModifier = TraceRequestModifier.default
    self.requestModifiers = [HTTPRequestHeadersModifier.defaultHeaderModifier, modifier, traceModifier]
  }
}

public extension HackerNews {
  /// Fetches the current top stories.
  /// - Parameter limit: The maximum number of stories to fetch. Fewer are returned when the feed is
  ///   shorter than the limit.
  /// - Returns: The stories, in the order the feed lists them.
  func topStories(limit: Int = 20) async throws -> [Item] {
    precondition(limit > 0, "Limit must be greater than zero")
    let stories = try await Array(stories(type: StoryType.top.rawValue).prefix(limit))
    let allResults = try await withThrowingTaskGroup(of: (Int, Item).self, returning: [Int: Item].self) { taskGroup in
      for storyId in stories {
        taskGroup.addTask {
          let item = try await self.item(id: storyId)
          return (storyId, item)
        }
      }
      var results: [Int: Item] = [:]
      for try await result in taskGroup {
        results[result.0] = result.1
      }
      return results
    }

    return stories.compactMap { allResults[$0] }
  }

  func stories(type: String) async throws -> [Int] {
    let request = try StoryListRequest(environment, storyType: type)
    return try await object(for: request, delegate: requestDelegate)
  }

  func item(id: Int) async throws -> Item {
    try await object(for: ItemRequest(environment, item: id), delegate: requestDelegate)
  }
}

#if canImport(ObjectiveC) && canImport(Security) && canImport(CryptoKit)
public extension HackerNews {
  /// Creates a client that accepts the server only when its certificate chain contains a pinned
  /// public key, on top of the system's own validation.
  ///
  /// Compute a pin from the server's certificate, and include a backup pin, such as the key of the
  /// next certificate or of an intermediate CA, so a certificate change does not lock users out:
  ///
  /// ```sh
  /// openssl s_client -connect hacker-news.firebaseio.com:443 -servername hacker-news.firebaseio.com </dev/null \
  ///   | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64
  /// ```
  ///
  /// ```swift
  /// let pins = HTTPPublicKeyPinning(publicKeyHashes: ["<primary pin>", "<backup pin>"],
  ///                                 hosts: ["hacker-news.firebaseio.com"])
  /// let client = HackerNews(pinning: pins)
  /// ```
  ///
  /// - Parameters:
  ///   - session: The session used for all requests. Its own delegate must not handle server trust
  ///     challenges, or it replaces the pinning.
  ///   - pinning: The public key pins.
  convenience init(session: URLSession = URLSession(configuration: .default, delegate: nil, delegateQueue: nil),
                   pinning: HTTPPublicKeyPinning) {
    self.init(session: session, requestDelegate: HTTPSecurityDelegate(pinning: pinning))
  }
}
#endif
