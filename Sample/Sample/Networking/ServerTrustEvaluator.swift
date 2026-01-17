//
//  ServerTrustEvaluator.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/10/25.
//

#if canImport(Security)
import Foundation
import HTTPRequestable
@preconcurrency import Security

public final class ServerTrustEvaluator: NSObject, HTTPServerTrustEvaluating, URLSessionDelegate, @unchecked Sendable {
  /// Indicates whether certificate pinning is enabled.
  var isCertificatePinningEnabled: Bool = true

  /// The set of certificates used for trust evaluation.
  let certificates: Set<SecCertificate>

  /// Initializes a new `ServerTrustEvaluator` with the specified certificates.
  ///
  /// - Parameter certificates: A set of certificates to use for trust evaluation. Defaults to an empty set.
  public init(certificates: Set<SecCertificate> = Set(Bundle.main.certificates)) {
    self.certificates = certificates
  }

  /// Handles a URL session authentication challenge asynchronously.
  ///
  /// - Parameters:
  ///   - session: The URL session that received the challenge.
  ///   - challenge: The authentication challenge to handle.
  /// - Returns: A tuple containing the disposition and credential for the challenge.
  public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
    isCertificatePinningEnabled ? evaluate(challenge: challenge, certificates: certificates) :
      accept(challenge: challenge, certificates: certificates)
  }
}
#endif
