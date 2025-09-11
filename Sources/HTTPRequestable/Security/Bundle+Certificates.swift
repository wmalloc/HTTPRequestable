//
//  Bundle+Certificates.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/29/25.
//

#if canImport(Security)
import Foundation
@preconcurrency import Security

public extension Bundle {
  /// A set of common file extensions for certificate files.
  ///
  /// This property includes extensions such as `.cer`, `.crt`, and `.der`, which are
  /// commonly used for X.509 certificates.
  @inlinable
  static var certificateExtensions: Set<String> {
    [".cer", ".CER", ".crt", ".CRT", ".der", ".DER"]
  }

  /// Retrieves all certificates from the specified bundle and directory.
  ///
  /// - Parameters:
  ///   - bundle: The bundle to search for certificates. Defaults to the main bundle.
  ///   - directory: The directory within the bundle to search. Defaults to `nil`.
  /// - Returns: An array of `SecCertificate` objects representing the certificates found.
  static func certificates(in bundle: Bundle = .main, inDirectory directory: String? = nil) -> [SecCertificate] {
    bundle.certificates(inDirectory: directory)
  }

  /// Retrieves all certificates from the current bundle and specified directory.
  ///
  /// - Parameter directory: The directory within the bundle to search. Defaults to `nil`.
  /// - Returns: An array of `SecCertificate` objects representing the certificates found.
  func certificates(inDirectory directory: String? = nil) -> [SecCertificate] {
    let paths = paths(forResourcesOfTypes: Self.certificateExtensions, inDirectory: directory)
    return paths.compactMap { path in
      guard let certificateData = try? Data(contentsOf: URL(fileURLWithPath: path)) as CFData,
            let certificate = SecCertificateCreateWithData(nil, certificateData)
      else {
        return nil
      }
      return certificate
    }
  }

  /// Retrieves all certificates from the current bundle.
  ///
  /// - Returns: An array of `SecCertificate` objects representing the certificates found.
  var certificates: [SecCertificate] {
    certificates()
  }

  /// Retrieves the paths of resources with the specified types in the given directory.
  ///
  /// - Parameters:
  ///   - types: A sequence of file extensions to search for.
  ///   - directory: The directory within the bundle to search. Defaults to `nil`.
  /// - Returns: An array of file paths matching the specified types.
  func paths(forResourcesOfTypes types: some Sequence<String>, inDirectory directory: String? = nil) -> [String] {
    Array(Set(types.flatMap { paths(forResourcesOfType: $0, inDirectory: directory) }))
  }
}

#endif
