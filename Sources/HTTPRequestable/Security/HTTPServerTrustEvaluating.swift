//
//  File.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/29/25.
//

#if canImport(Security)
import Foundation
@preconcurrency import Security

public final class ServerTrustEvaluator: NSObject, HTTPServerTrustEvaluating, URLSessionDelegate, @unchecked Sendable {
  var isCertificatePinningEnabled: Bool = true
  let certificates: Set<SecCertificate>
  
  public init(certificates: Set<SecCertificate> = []) {
    self.certificates = certificates
  }
  
  public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
    isCertificatePinningEnabled ? evaluate(challenge: challenge, certificates: certificates) : accept(challenge: challenge, certificates: certificates)
  }
}

public protocol HTTPServerTrustEvaluating {
  func evaluate(challenge: URLAuthenticationChallenge, certificates: Set<SecCertificate>) -> (URLSession.AuthChallengeDisposition, URLCredential?)
  func evaluate(challenge: URLAuthenticationChallenge, certificates: Set<SecCertificate>, completion: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
  func accept(challenge: URLAuthenticationChallenge, certificates: Set<SecCertificate>) -> (URLSession.AuthChallengeDisposition, URLCredential?)

  func evaluate(trust: SecTrust, certificates: Set<SecCertificate>) throws(TrustError)
}

extension HTTPServerTrustEvaluating {
  public func evaluate(challenge: URLAuthenticationChallenge, certificates: Set<SecCertificate>) -> (URLSession.AuthChallengeDisposition, URLCredential?) {
    guard let trust = challenge.protectionSpace.serverTrust else {
      return (.cancelAuthenticationChallenge, nil)
    }
    do {
      try evaluate(trust: trust, certificates: certificates)
      return (.useCredential, URLCredential(trust: trust))
    } catch {
      return (.cancelAuthenticationChallenge, nil)
    }
  }
  
  public func evaluate(challenge: URLAuthenticationChallenge, certificates: Set<SecCertificate>, completion: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    let result = evaluate(challenge: challenge, certificates: certificates)
    completion(result.0, result.1)
  }

  public func accept(challenge: URLAuthenticationChallenge, certificates: Set<SecCertificate>) -> (URLSession.AuthChallengeDisposition, URLCredential?) {
    guard let trust = challenge.protectionSpace.serverTrust else {
      return (.cancelAuthenticationChallenge, nil)
    }
    let credential = URLCredential(trust: trust)
    return (.useCredential, credential)
  }
  
  public func evaluate(trust: SecTrust, certificates: Set<SecCertificate>) throws(TrustError) {
    guard let trustCertificates = trust.certificates else {
      throw .certificateNotFound
    }
    
    let certificateKeys = Set(certificates.publicKeysData)
    let trustCertificateKeys = Set(trustCertificates.publicKeysData)
    let isDisjoint = trustCertificateKeys.isDisjoint(with: certificateKeys)
    if isDisjoint {
      throw .certificatesDoNotMatch
    }
  }
}
#endif
