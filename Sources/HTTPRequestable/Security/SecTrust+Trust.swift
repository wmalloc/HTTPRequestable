//
//  SecTrust+Trust.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/6/25.
//

#if canImport(Security)
import Foundation
@preconcurrency import Security

public extension SecTrust {
  /// Retrieves the certificate chain associated with the trust object.
  ///
  /// - Returns: An array of `SecCertificate` objects representing the certificate chain, or `nil`
  /// if the certificate chain cannot be retrieved.
  ///
  /// This property uses `SecTrustCopyCertificateChain` to obtain the certificates. Note that this
  /// method may return `nil` if the trust object does not contain a valid certificate chain.
  var certificates: [SecCertificate]? {
    SecTrustCopyCertificateChain(self) as? [SecCertificate]
  }
}

#endif
