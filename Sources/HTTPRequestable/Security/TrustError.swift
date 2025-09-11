//
//  TrustError.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/6/25.
//

import Foundation

/// An enumeration representing errors that can occur during trust evaluation.
///
/// `TrustError` is used to indicate specific issues encountered when working with
/// certificates and trust validation. These errors can be used to diagnose and handle
/// trust-related failures in a secure communication process.
public enum TrustError: Error {
  /// Indicates that a required certificate could not be found.
  ///
  /// This error may occur when attempting to locate a certificate in a bundle or
  /// during a trust evaluation process.
  case certificateNotFound

  /// Indicates that the provided certificates do not match the expected values.
  ///
  /// This error may occur when validating a certificate chain or comparing certificates
  /// for equality.
  case certificatesDoNotMatch
}
