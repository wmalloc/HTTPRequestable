//
//  RequestDelegateTests.swift
//
//  Created by Waqar Malik on 11/26/26.
//

import Foundation
@testable import HackerNewsKit
import HTTPRequestable
import MockURLProtocol
import Synchronization
import Testing

/// Records the URL of every task it collects metrics for, which `URLSession` reports for each task.
private final class RecordingDelegate: NSObject, URLSessionTaskDelegate, Sendable {
  let urls = Mutex<[URL]>([])

  func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
    if let url = task.originalRequest?.url {
      urls.withLock { $0.append(url) }
    }
  }
}

@Suite("HackerNews request delegate")
struct RequestDelegateTests {
  private let environment = HTTPEnvironment(authority: "hacker-news.firebaseio.com", path: "/v0")

  private func mockSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: configuration)
  }

  private func stub(_ url: URL, with body: String) async throws {
    try await MockURLProtocol.setRequestHandler({ _ in
      (Data(body.utf8), HTTPURLResponse.ok(url: url))
    }, forIdentifier: url)
  }

  @Test("Without a request delegate the library's default protection applies")
  func defaultDelegate() {
    #expect(HackerNews(session: mockSession()).requestDelegate == nil)
  }

  @Test("The request delegate is used for story lists and items")
  func delegateReachesRequests() async throws {
    let recorder = RecordingDelegate()
    let api = HackerNews(session: mockSession(), requestDelegate: recorder)
    // A story type and item id no other test stubs, since handlers are keyed by URL.
    let storyType = "delegate-\(UUID().uuidString)"
    let itemID = Int.random(in: 1000000000 ... 2000000000)
    let listURL = try StoryListRequest(environment, storyType: storyType).url
    let itemURL = try ItemRequest(environment, item: itemID).url
    try await stub(listURL, with: "[\(itemID)]")
    try await stub(itemURL, with: """
    {"by": "a", "id": \(itemID), "score": 1, "time": 1175714200, "title": "t", "type": "story"}
    """)

    #expect(try await api.stories(type: storyType) == [itemID])
    #expect(try await api.item(id: itemID).id == itemID)
    #expect(recorder.urls.withLock { $0 } == [listURL, itemURL])
  }

  #if canImport(ObjectiveC) && canImport(Security) && canImport(CryptoKit)
  @Test("Pinning sends every request with a security delegate holding the pins")
  func pinning() throws {
    let pins = HTTPPublicKeyPinning(publicKeyHashes: ["primary=", "backup="], hosts: ["hacker-news.firebaseio.com"])
    let api = HackerNews(session: mockSession(), pinning: pins)
    let delegate = try #require(api.requestDelegate as? HTTPSecurityDelegate)
    #expect(delegate.pinning == pins)
    #expect(delegate.redirectPolicy === HTTPRedirectPolicy.default)
  }
  #endif
}
