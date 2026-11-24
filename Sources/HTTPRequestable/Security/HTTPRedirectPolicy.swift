//
//  HTTPRedirectPolicy.swift
//
//  Created by Waqar Malik on 11/21/26.
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
#endif
import HTTPTypes

/// A task delegate that decides whether, and how, a redirect is followed.
///
/// By default `URLSession` follows every redirect and forwards the request's headers to the new
/// location. This policy blocks downgrades from `https` to another scheme and removes credential
/// headers when a redirect leaves the origin (scheme, host and port) of the request.
///
/// It is applied automatically through ``HTTPSecurityDelegate``, which also wraps any delegate you pass
/// to a request. Pass an `HTTPRedirectPolicy` as the delegate to use a policy of your own. On platforms
/// without the Objective-C runtime a delegate cannot be wrapped, so one you pass replaces this policy.
public final class HTTPRedirectPolicy: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
  /// The policy used when a request has no delegate: blocks downgrades and strips sensitive headers
  /// on cross-origin redirects.
  public static let `default` = HTTPRedirectPolicy()

  /// Header fields that are removed when a redirect leaves the origin of the request.
  public static let defaultSensitiveHeaders: Set<HTTPField.Name> = [
    .authorization, .cookie, .proxyAuthorization, HTTPField.Name("X-API-Key")!
  ]

  /// When `true`, a redirect from `https` to any other scheme is not followed.
  public let blocksDowngrade: Bool

  /// Header fields removed from a redirected request that leaves the origin of the original request.
  public let sensitiveHeaders: Set<HTTPField.Name>

  /// When non-nil, redirects are only followed to these hosts (case-insensitive). The redirect
  /// response itself is returned to the caller for any other host.
  public let allowedHosts: Set<String>?

  /// - Parameters:
  ///   - blocksDowngrade: Block redirects from `https` to another scheme. Defaults to `true`.
  ///   - sensitiveHeaders: Fields removed on cross-origin redirects. Defaults to `defaultSensitiveHeaders`.
  ///   - allowedHosts: Hosts redirects may go to, or `nil` for any host. Defaults to `nil`.
  public init(blocksDowngrade: Bool = true, sensitiveHeaders: Set<HTTPField.Name> = HTTPRedirectPolicy.defaultSensitiveHeaders,
              allowedHosts: Set<String>? = nil) {
    self.blocksDowngrade = blocksDowngrade
    self.sensitiveHeaders = sensitiveHeaders
    self.allowedHosts = allowedHosts
  }

  public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                         newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
    completionHandler(redirectedRequest(request, from: task.currentRequest?.url ?? task.originalRequest?.url))
  }

  /// The request to follow for a redirect, or `nil` when the redirect must not be followed.
  ///
  /// - Parameters:
  ///   - newRequest: The request `URLSession` proposes for the redirect target.
  ///   - originalURL: The URL that answered with the redirect.
  func redirectedRequest(_ newRequest: URLRequest, from originalURL: URL?) -> URLRequest? {
    guard let newURL = newRequest.url else {
      return nil
    }
    if blocksDowngrade, originalURL?.scheme?.lowercased() == "https", newURL.scheme?.lowercased() != "https" {
      return nil
    }
    if let allowedHosts, !allowedHosts.contains(where: { $0.lowercased() == newURL.host?.lowercased() }) {
      return nil
    }
    // Without a known origin, assume the redirect is cross-origin.
    if let originalURL, Self.isSameOrigin(originalURL, newURL) {
      return newRequest
    }
    return newRequest.removingHeaders(sensitiveHeaders)
  }

  private static func isSameOrigin(_ lhs: URL, _ rhs: URL) -> Bool {
    lhs.scheme?.lowercased() == rhs.scheme?.lowercased()
      && lhs.host?.lowercased() == rhs.host?.lowercased()
      && lhs.port == rhs.port
  }

  /// The request to send after interceptors forward `request`, given the request that entered the chain.
  ///
  /// Interceptors run after request modifiers, so `original` may already carry credentials meant for its
  /// origin. When `request` has a different origin (scheme and authority), sensitive header values it
  /// carried over from `original` are removed; values an interceptor set itself are kept. A move from
  /// `https` to another scheme is refused when ``blocksDowngrade`` is `true`.
  ///
  /// - Parameters:
  ///   - request: The request the interceptors forwarded.
  ///   - original: The request that entered the interceptor chain.
  /// - Returns: `request`, without the sensitive header values carried over from `original` when the
  ///   origin changed.
  /// - Throws: `URLError(.appTransportSecurityRequiresSecureConnection)` for a blocked downgrade.
  func forwardedRequest(_ request: HTTPRequest, original: HTTPRequest) throws -> HTTPRequest {
    if blocksDowngrade, original.scheme?.lowercased() == "https", request.scheme?.lowercased() != "https" {
      throw URLError(.appTransportSecurityRequiresSecureConnection)
    }
    if original.scheme?.lowercased() == request.scheme?.lowercased(),
       original.authority?.lowercased() == request.authority?.lowercased() {
      return request
    }

    var carried: [HTTPField.Name: Set<String>] = [:]
    for field in original.headerFields where sensitiveHeaders.contains(field.name) {
      carried[field.name, default: []].insert(field.value)
    }
    guard !carried.isEmpty else {
      return request
    }
    var forwarded = request
    forwarded.headerFields = HTTPFields(request.headerFields.filter { carried[$0.name]?.contains($0.value) != true })
    return forwarded
  }
}

private extension URLRequest {
  func removingHeaders(_ names: Set<HTTPField.Name>) -> URLRequest {
    var request = self
    for name in names {
      request.setValue(nil, forHTTPHeaderField: name.rawName)
      request.setValue(nil, forHTTPHeaderField: name.canonicalName)
    }
    return request
  }
}
