//
//  SecTrust+Trust.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/6/25.
//

#if canImport(Security)
import Foundation
@preconcurrency import Security

/// This extension provides convenience methods for working with `SecTrust` objects.
///
/// `SecTrust` is an opaque type that represents a trust management object. It is used to evaluate
/// the trustworthiness of a certificate chain, typically in SSL/TLS connections.
///
/// The `certificates` property in this extension allows you to retrieve the certificate chain
/// associated with the `SecTrust` object. This can be useful for inspecting the certificates
/// or performing custom validation.
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
