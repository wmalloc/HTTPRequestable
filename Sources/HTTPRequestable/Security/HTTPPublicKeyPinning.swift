//
//  HTTPPublicKeyPinning.swift
//
//  Created by Waqar Malik on 11/21/26.
//

#if canImport(Security) && canImport(CryptoKit)
import CryptoKit
import Foundation
@preconcurrency import Security

/// Public key pins for a set of hosts.
///
/// A pin is the base64 encoded SHA-256 hash of a certificate's DER encoded `SubjectPublicKeyInfo`, the
/// format used by HPKP and most pinning tools. To compute one from a certificate:
///
/// ```sh
/// openssl x509 -in cert.pem -pubkey -noout | openssl pkey -pubin -outform der \
///   | openssl dgst -sha256 -binary | base64
/// ```
///
/// The system validates the certificate chain first (expiry, hostname and a trusted root). The
/// connection is then accepted only when the public key of at least one certificate in the validated
/// chain matches a pin. Include a backup pin, for example the key of your next certificate or of an
/// intermediate CA, so you can rotate certificates without shipping an update first.
///
/// Supported key types are RSA (2048, 3072 and 4096 bits) and EC (P-256, P-384 and P-521). A certificate
/// with any other key never matches.
public struct HTTPPublicKeyPinning: Sendable, Hashable {
  /// The pins, as base64 encoded SHA-256 hashes of `SubjectPublicKeyInfo`.
  public let publicKeyHashes: Set<String>

  /// Hosts the pins apply to, or `nil` for every host. Matching is case-insensitive.
  public let hosts: Set<String>?

  /// Whether a pinned host also covers its subdomains, so `example.com` covers `api.example.com`.
  public let includesSubdomains: Bool

  /// - Parameters:
  ///   - publicKeyHashes: The pins. An empty set rejects every connection the pins apply to.
  ///   - hosts: Hosts the pins apply to, or `nil` for every host. Defaults to `nil`.
  ///   - includesSubdomains: Whether pinned hosts cover their subdomains. Defaults to `false`.
  public init(publicKeyHashes: some Sequence<String>, hosts: Set<String>? = nil, includesSubdomains: Bool = false) {
    self.publicKeyHashes = Set(publicKeyHashes)
    self.hosts = hosts.map { Set($0.map { $0.lowercased() }) }
    self.includesSubdomains = includesSubdomains
  }

  /// Pins the public keys of `certificates`, for example ones loaded with `Bundle.certificates`.
  ///
  /// - Parameters:
  ///   - certificates: Certificates whose public keys are pinned.
  ///   - additionalPublicKeyHashes: Further pins, such as backup keys. Defaults to none.
  ///   - hosts: Hosts the pins apply to, or `nil` for every host. Defaults to `nil`.
  ///   - includesSubdomains: Whether pinned hosts cover their subdomains. Defaults to `false`.
  public init(certificates: some Sequence<SecCertificate>, additionalPublicKeyHashes: some Sequence<String> = [String](),
              hosts: Set<String>? = nil, includesSubdomains: Bool = false)
  {
    let hashes = certificates.compactMap(Self.publicKeyHash(for:))
    self.init(publicKeyHashes: hashes + Array(additionalPublicKeyHashes), hosts: hosts, includesSubdomains: includesSubdomains)
  }

  /// Whether the pins apply to connections to `host`.
  public func applies(toHost host: String) -> Bool {
    guard let hosts else {
      return true
    }
    let host = host.lowercased()
    if hosts.contains(host) {
      return true
    }
    return includesSubdomains && hosts.contains { host.hasSuffix("." + $0) }
  }

  /// Validates `trust` with the system, then checks that its chain contains a pinned public key.
  ///
  /// - Throws: `.evaluationFailed` when the system rejects the chain, `.certificateNotFound` when the
  ///   chain is empty, and `.certificatesDoNotMatch` when no public key in it is pinned.
  public func evaluate(_ trust: SecTrust) throws(TrustError) {
    var evaluationError: CFError?
    guard SecTrustEvaluateWithError(trust, &evaluationError) else {
      throw .evaluationFailed
    }
    guard let chain = trust.certificates, !chain.isEmpty else {
      throw .certificateNotFound
    }
    guard chain.contains(where: { Self.publicKeyHash(for: $0).map(publicKeyHashes.contains) ?? false }) else {
      throw .certificatesDoNotMatch
    }
  }
}

public extension HTTPPublicKeyPinning {
  /// The pin for `certificate`: the base64 encoded SHA-256 hash of its `SubjectPublicKeyInfo`, or `nil`
  /// when its key type is not supported.
  static func publicKeyHash(for certificate: SecCertificate) -> String? {
    SecCertificateCopyKey(certificate).flatMap(publicKeyHash(for:))
  }

  /// The pin for `key`, or `nil` when its type is not supported.
  static func publicKeyHash(for key: SecKey) -> String? {
    guard let attributes = SecKeyCopyAttributes(key) as? [CFString: Any],
          let keyType = attributes[kSecAttrKeyType] as? String,
          let keySize = attributes[kSecAttrKeySizeInBits] as? Int,
          let header = subjectPublicKeyInfoHeader(keyType: keyType, keySize: keySize),
          let keyData = SecKeyCopyExternalRepresentation(key, nil) as Data?
    else {
      return nil
    }
    return Data(SHA256.hash(data: header + keyData)).base64EncodedString()
  }

  /// The DER prefix that turns the key's external representation (PKCS #1 for RSA, X9.63 for EC) into
  /// a `SubjectPublicKeyInfo`.
  internal static func subjectPublicKeyInfoHeader(keyType: String, keySize: Int) -> Data? {
    let family = if keyType == (kSecAttrKeyTypeRSA as String) {
      "RSA"
    } else if keyType == (kSecAttrKeyTypeECSECPrimeRandom as String) {
      "EC"
    } else {
      ""
    }
    return switch (family, keySize) {
    case ("RSA", 2048):
      Data([0x30, 0x82, 0x01, 0x22, 0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01,
            0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0F, 0x00])
    case ("RSA", 3072):
      Data([0x30, 0x82, 0x01, 0xA2, 0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01,
            0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x8F, 0x00])
    case ("RSA", 4096):
      Data([0x30, 0x82, 0x02, 0x22, 0x30, 0x0D, 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01,
            0x01, 0x05, 0x00, 0x03, 0x82, 0x02, 0x0F, 0x00])
    case ("EC", 256):
      Data([0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01, 0x06, 0x08, 0x2A,
            0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07, 0x03, 0x42, 0x00])
    case ("EC", 384):
      Data([0x30, 0x76, 0x30, 0x10, 0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01, 0x06, 0x05, 0x2B,
            0x81, 0x04, 0x00, 0x22, 0x03, 0x62, 0x00])
    case ("EC", 521):
      Data([0x30, 0x81, 0x9B, 0x30, 0x10, 0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01, 0x06, 0x05,
            0x2B, 0x81, 0x04, 0x00, 0x23, 0x03, 0x81, 0x86, 0x00])
    default:
      nil
    }
  }
}
#endif
