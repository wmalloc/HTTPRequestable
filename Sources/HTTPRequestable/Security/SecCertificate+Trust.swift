//
//  SecCertificate+Trust.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/6/25.
//

#if canImport(Security)
import Foundation
@preconcurrency import Security

/// `SecCertificate` is an opaque Core Foundation type that represents an X.509 certificate.
///
/// Certificates are used in cryptographic operations, such as establishing trust between
/// communicating parties and verifying identity. They are essential components in protocols
/// like SSL/TLS for secure network communication.
///
/// You can use `SecCertificate` to:
/// - Access the raw certificate data.
/// - Extract the public key contained within the certificate.
/// - Validate the certificate's trust using appropriate policies.
///
/// Common operations involving `SecCertificate` include:
/// - Creating a certificate from DER-encoded data using `SecCertificateCreateWithData`.
/// - Extracting the certificate's public key, either directly or via a trust evaluation.
/// - Retrieving certificate properties for display or validation.
///
/// `SecCertificate` is provided by the Security framework on Apple platforms and interoperates
/// with other security objects such as `SecKey` and `SecTrust`.
///
/// For more information, consult the official Apple documentation:
/// https://developer.apple.com/documentation/security/seccertificate
public extension SecCertificate {
  var publicKey: SecKey? {
    let policy = SecPolicyCreateBasicX509()
    var trust: SecTrust?
    let trustCreationStatus = SecTrustCreateWithCertificates(self, policy, &trust)
    guard let createdTrust = trust, trustCreationStatus == errSecSuccess else {
      return nil
    }

    return SecTrustCopyKey(createdTrust)
  }

  @inlinable
  var data: Data {
    SecCertificateCopyData(self) as Data
  }

  var publicKeyData: Data? {
    guard let publicKey else {
      return nil
    }
    return SecKeyCopyExternalRepresentation(publicKey, nil) as? Data
  }
}

/// This extension provides convenience methods for sequences of `SecCertificate` objects.
///
/// It allows you to:
/// - Retrieve the raw data of all certificates in the sequence.
/// - Extract the public keys from all certificates in the sequence.
/// - Extract the public key data from all certificates in the sequence.
///
/// These methods are useful when working with multiple certificates, such as in a certificate chain.
public extension Sequence where Iterator.Element == SecCertificate {
  /// Retrieves the raw data of all certificates in the sequence.
  ///
  /// - Returns: An array of `Data` objects representing the raw data of each certificate.
  @inlinable
  var data: [Data] {
    map(\.data)
  }

  /// Extracts the public keys from all certificates in the sequence.
  ///
  /// - Returns: An array of `SecKey` objects representing the public keys of each certificate.
  @inlinable
  var publicKeys: [SecKey] {
    compactMap(\.publicKey)
  }

  /// Extracts the public key data from all certificates in the sequence.
  ///
  /// - Returns: An array of `Data` objects representing the public key data of each certificate.
  @inlinable
  var publicKeysData: [Data] {
    compactMap(\.publicKeyData)
  }
}

#endif
