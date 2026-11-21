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
/// It is used automatically when no `delegate` is passed to a request. A delegate you pass replaces it,
/// so forward `urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)` to a
/// policy of your own to keep the protection.
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
