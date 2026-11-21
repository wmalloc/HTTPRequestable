//
//  HTTPSecurityDelegate.swift
//
//  Created by Waqar Malik on 11/21/26.
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
#endif

#if canImport(ObjectiveC) && canImport(Security) && canImport(CryptoKit)
@preconcurrency import Security

/// A task delegate that applies a redirect policy, optional public key pinning and an optional response
/// size limit, and forwards every other callback to the delegate you give it.
///
/// Requests made through this library use ``HTTPSecurityDelegate/default`` when you pass no delegate.
/// A delegate you pass that is not an `HTTPSecurityDelegate` or an ``HTTPRedirectPolicy`` is wrapped in
/// one automatically, so a progress or metrics delegate does not turn the redirect protection off. To
/// pin keys or limit response size, pass an instance configured for that:
///
/// ```swift
/// let pins = HTTPPublicKeyPinning(publicKeyHashes: ["base64…", "backup-base64…"], hosts: ["api.example.com"])
/// let delegate = HTTPSecurityDelegate(pinning: pins, maxResponseSize: 10_000_000, delegate: progressDelegate)
/// let response = try await session.performRequest(request, delegate: delegate)
/// ```
///
/// - Important: `URLSession` sends session-level challenges, such as server trust, to the session's own
///   delegate when it implements `urlSession(_:didReceive:completionHandler:)`, before any task delegate.
///   Pinning here only takes effect for sessions whose delegate does not handle those challenges.
public final class HTTPSecurityDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
  /// Uses ``HTTPRedirectPolicy/default`` with no pinning and no response size limit.
  public static let `default` = HTTPSecurityDelegate()

  /// The policy applied to redirects before the wrapped delegate sees them, or `nil` to follow
  /// redirects as `URLSession` proposes them.
  public let redirectPolicy: HTTPRedirectPolicy?

  /// The pins checked for server trust challenges, or `nil` to use system validation only.
  public let pinning: HTTPPublicKeyPinning?

  /// The largest response body, in bytes, accepted by `performRequest`, or `nil` for no limit. A larger
  /// response fails with `URLError(.dataLengthExceedsMaximum)` and is not read further.
  ///
  /// The limit applies to in-memory responses from `performRequest` and `object(for:)`. It does not
  /// apply to `download(for:)`, which writes to disk, or to `bytes(for:)`, which you read yourself.
  public let maxResponseSize: Int?

  /// The delegate that receives every callback this one does not consume.
  public let delegate: (any URLSessionTaskDelegate)?

  /// - Parameters:
  ///   - redirectPolicy: Applied to redirects. Defaults to ``HTTPRedirectPolicy/default``.
  ///   - pinning: Pins for server trust challenges. Defaults to `nil`.
  ///   - maxResponseSize: Largest accepted response body in bytes. Defaults to `nil`.
  ///   - delegate: Receives all other callbacks. Defaults to `nil`.
  public init(redirectPolicy: HTTPRedirectPolicy? = .default, pinning: HTTPPublicKeyPinning? = nil,
              maxResponseSize: Int? = nil, delegate: (any URLSessionTaskDelegate)? = nil) {
    self.redirectPolicy = redirectPolicy
    self.pinning = pinning
    self.maxResponseSize = maxResponseSize.map { Swift.max($0, 0) }
    self.delegate = delegate
  }

  // MARK: Redirects

  public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                         newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
    let originalURL = task.currentRequest?.url ?? task.originalRequest?.url
    guard let request = redirectPolicy.map({ $0.redirectedRequest(request, from: originalURL) }) ?? request else {
      completionHandler(nil)
      return
    }
    if delegate?.urlSession?(session, task: task, willPerformHTTPRedirection: response, newRequest: request,
                             completionHandler: completionHandler) != nil {
      return
    }
    completionHandler(request)
  }

  // MARK: Challenges

  public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge,
                         completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    handle(challenge, session: session, task: task, completionHandler: completionHandler)
  }

  public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                         completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    handle(challenge, session: session, task: nil, completionHandler: completionHandler)
  }

  private func handle(_ challenge: URLAuthenticationChallenge, session: URLSession, task: URLSessionTask?,
                      completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    let protectionSpace = challenge.protectionSpace
    if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let pinning,
       pinning.applies(toHost: protectionSpace.host) {
      guard let trust = protectionSpace.serverTrust else {
        completionHandler(.cancelAuthenticationChallenge, nil)
        return
      }
      do {
        try pinning.evaluate(trust)
        completionHandler(.useCredential, URLCredential(trust: trust))
      } catch {
        completionHandler(.cancelAuthenticationChallenge, nil)
      }
      return
    }

    // Not ours to decide: let the wrapped delegate answer, or fall back to the system.
    if let task, delegate?.urlSession?(session, task: task, didReceive: challenge, completionHandler: completionHandler) != nil {
      return
    }
    if delegate?.urlSession?(session, didReceive: challenge, completionHandler: completionHandler) != nil {
      return
    }
    completionHandler(.performDefaultHandling, nil)
  }

  // MARK: Forwarding

  // Every other delegate callback, including data and download delegate methods, goes straight to the
  // wrapped delegate.

  override public func responds(to aSelector: Selector!) -> Bool {
    super.responds(to: aSelector) || (delegate?.responds(to: aSelector) ?? false)
  }

  override public func conforms(to aProtocol: Protocol) -> Bool {
    super.conforms(to: aProtocol) || (delegate?.conforms(to: aProtocol) ?? false)
  }

  override public func forwardingTarget(for aSelector: Selector!) -> Any? {
    if let delegate, delegate.responds(to: aSelector) {
      return delegate
    }
    return super.forwardingTarget(for: aSelector)
  }
}

extension URLSession {
  /// The delegate to give a task: `delegate` wrapped so redirect protection always applies.
  static func secureTaskDelegate(_ delegate: (any URLSessionTaskDelegate)?) -> any URLSessionTaskDelegate {
    switch delegate {
    case nil:
      HTTPSecurityDelegate.default
    case let delegate as HTTPSecurityDelegate:
      delegate
    case let delegate as HTTPRedirectPolicy:
      delegate
    case let delegate?:
      HTTPSecurityDelegate(delegate: delegate)
    }
  }

  /// The response size limit configured on `delegate`, if any.
  static func maxResponseSize(of delegate: any URLSessionTaskDelegate) -> Int? {
    (delegate as? HTTPSecurityDelegate)?.maxResponseSize
  }
}

#else

extension URLSession {
  /// The delegate to give a task. Without the Objective-C runtime a delegate cannot be wrapped, so a
  /// delegate you pass replaces the default redirect policy.
  static func secureTaskDelegate(_ delegate: (any URLSessionTaskDelegate)?) -> any URLSessionTaskDelegate {
    delegate ?? HTTPRedirectPolicy.default
  }

  static func maxResponseSize(of delegate: any URLSessionTaskDelegate) -> Int? {
    nil
  }
}

#endif
