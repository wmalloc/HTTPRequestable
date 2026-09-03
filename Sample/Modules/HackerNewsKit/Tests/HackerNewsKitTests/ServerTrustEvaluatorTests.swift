//
//  ServerTrustEvaluatorTests.swift
//
//  Created by Waqar Malik on 8/27/26.
//

#if canImport(Security)
import Foundation
@testable import HackerNewsKit
import HTTPRequestable
import Security
import Testing

@Suite("ServerTrustEvaluator")
struct ServerTrustEvaluatorTests {
  /// A challenge for a protection space that carries no `serverTrust`, which is the only kind that
  /// can be built without a live TLS handshake.
  private func makeChallenge(authenticationMethod: String = NSURLAuthenticationMethodServerTrust) -> URLAuthenticationChallenge {
    let space = URLProtectionSpace(host: "hacker-news.firebaseio.com", port: 443, protocol: "https",
                                   realm: nil, authenticationMethod: authenticationMethod)
    return URLAuthenticationChallenge(protectionSpace: space, proposedCredential: nil, previousFailureCount: 0,
                                      failureResponse: nil, error: nil, sender: NoopChallengeSender())
  }

  @Test("Pins certificates by default")
  func pinningIsEnabledByDefault() {
    let evaluator = ServerTrustEvaluator(certificates: [])
    #expect(evaluator.isCertificatePinningEnabled)
  }

  @Test("Keeps the certificates it was given")
  func storesCertificates() {
    let evaluator = ServerTrustEvaluator(certificates: [])
    #expect(evaluator.certificates.isEmpty)
  }

  @Test("Is usable as a URLSession delegate")
  func isSessionDelegate() {
    let evaluator = ServerTrustEvaluator(certificates: [])
    #expect(evaluator is any URLSessionDelegate)
    #expect(evaluator is any HTTPServerTrustEvaluating)
  }

  @Test("Cancels a challenge that carries no server trust", arguments: [true, false])
  func cancelsWithoutServerTrust(pinningEnabled: Bool) async {
    let evaluator = ServerTrustEvaluator(certificates: [])
    evaluator.isCertificatePinningEnabled = pinningEnabled
    let challenge = makeChallenge()
    #expect(challenge.protectionSpace.serverTrust == nil)

    let (disposition, credential) = await evaluator.urlSession(URLSession.shared, didReceive: challenge)
    #expect(disposition == .cancelAuthenticationChallenge)
    #expect(credential == nil)
  }

  @Test("Cancels a non trust challenge such as basic authentication")
  func cancelsNonTrustChallenge() async {
    let evaluator = ServerTrustEvaluator(certificates: [])
    let challenge = makeChallenge(authenticationMethod: NSURLAuthenticationMethodHTTPBasic)

    let (disposition, credential) = await evaluator.urlSession(URLSession.shared, didReceive: challenge)
    #expect(disposition == .cancelAuthenticationChallenge)
    #expect(credential == nil)
  }
}

/// `URLAuthenticationChallenge` requires a sender; nothing in these tests drives it.
private final class NoopChallengeSender: NSObject, URLAuthenticationChallengeSender {
  func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}
  func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}
  func cancel(_ challenge: URLAuthenticationChallenge) {}
}
#endif
