//
//  File.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/6/25.
//

#if canImport(Security)
import Foundation
@preconcurrency import Security

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

public extension Sequence where Iterator.Element == SecCertificate {
  var data: [Data] {
    map(\.data)
  }
  
  var publicKeys: [SecKey] {
    return compactMap(\.publicKey)
  }
  
  var publicKeysData: [Data] {
    return compactMap(\.publicKeyData)
  }
}

#endif
