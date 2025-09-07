//
//  File.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/6/25.
//

#if canImport(Security)
import Foundation
@preconcurrency import Security

public extension SecTrust {
  var certificates: [SecCertificate]? {
    SecTrustCopyCertificateChain(self) as? [SecCertificate]
  }
}

#endif
