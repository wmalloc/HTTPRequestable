//
//  HTTPServerTrustEvaluating.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/29/25.
//

#if canImport(Security)
import Foundation
@preconcurrency import Security
import OSLog

#if DEBUG
private let logger = Logger(.init(category: "HTTPRequestable"))
#else
private let logger = Logger(.disabled)
#endif

/**
 # HTTPServerTrustEvaluating
 This file provides the `HTTPServerTrustEvaluating` protocol and its default implementations,
 as well as the `ServerTrustEvaluator` class for handling server trust evaluation.
 */

public protocol HTTPServerTrustEvaluating {
  /// Evaluates a server trust challenge using the specified certificates.
  ///
  /// - Parameters:
  ///   - challenge: The server trust challenge to evaluate.
  ///   - certificates: The set of certificates to use for evaluation.
  /// - Returns: A tuple containing the disposition and credential for the challenge.
  func evaluate(challenge: URLAuthenticationChallenge, certificates: Set<SecCertificate>) -> (URLSession.AuthChallengeDisposition, URLCredential?)

  /// Evaluates a server trust challenge asynchronously using the specified certificates.
  ///
  /// - Parameters:
  ///   - challenge: The server trust challenge to evaluate.
  ///   - certificates: The set of certificates to use for evaluation.
  ///   - completion: A closure to call with the disposition and credential for the challenge.
  func evaluate(challenge: URLAuthenticationChallenge, certificates: Set<SecCertificate>, completion: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)

  /// Accepts a server trust challenge without validation.
  ///
  /// - Parameters:
  ///   - challenge: The server trust challenge to accept.
  ///   - certificates: The set of certificates to use for evaluation.
  /// - Returns: A tuple containing the disposition and credential for the challenge.
  func accept(challenge: URLAuthenticationChallenge, certificates: Set<SecCertificate>) -> (URLSession.AuthChallengeDisposition, URLCredential?)

  /// Evaluates a server trust object using the specified certificates.
  ///
  /// - Parameters:
  ///   - trust: The server trust object to evaluate.
  ///   - certificates: The set of certificates to use for evaluation.
  /// - Throws: A `TrustError` if the evaluation fails.
  func evaluate(trust: SecTrust, certificates: Set<SecCertificate>) throws(TrustError)
}

public extension HTTPServerTrustEvaluating {
  /// Default implementation for evaluating a server trust challenge.
  func evaluate(challenge: URLAuthenticationChallenge, certificates: Set<SecCertificate>) -> (URLSession.AuthChallengeDisposition, URLCredential?) {
    logger.trace("[IN]: \(#function)")
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

  /// Default implementation for evaluating a server trust challenge asynchronously.
  func evaluate(challenge: URLAuthenticationChallenge, certificates: Set<SecCertificate>, completion: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    logger.trace("[IN]: \(#function)")
    let result = evaluate(challenge: challenge, certificates: certificates)
    completion(result.0, result.1)
  }

  /// Default implementation for accepting a server trust challenge without validation.
  func accept(challenge: URLAuthenticationChallenge, certificates: Set<SecCertificate>) -> (URLSession.AuthChallengeDisposition, URLCredential?) {
    logger.trace("[IN]: \(#function)")
    guard let trust = challenge.protectionSpace.serverTrust else {
      return (.cancelAuthenticationChallenge, nil)
    }
    let exceptions = SecTrustCopyExceptions(trust)
    SecTrustSetExceptions(trust, exceptions)
    let credential = URLCredential(trust: trust)
    return (.useCredential, credential)
  }

  /// Default implementation for evaluating a server trust object.
  func evaluate(trust: SecTrust, certificates: Set<SecCertificate>) throws(TrustError) {
    logger.trace("[IN]: \(#function)")
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
