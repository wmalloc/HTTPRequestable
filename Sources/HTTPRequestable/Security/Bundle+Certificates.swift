//
//  File.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 8/29/25.
//

#if canImport(Security)
import Foundation
@preconcurrency import Security

public extension Bundle {
  @inlinable
  static var certificateExtensions: Set<String> {
    [".cer", ".CER", ".crt", ".CRT", ".der", ".DER"]
  }
  
  static func certificates(in bundle: Bundle = .main, inDirectory directory: String? = nil) -> [SecCertificate] {
    bundle.certificates(inDirectory: directory)
  }
  
  func certificates(inDirectory directory: String? = nil) -> [SecCertificate] {
    let paths = paths(forResourcesOfTypes: Self.certificateExtensions, inDirectory: directory)
    return paths.compactMap { path in
      guard let certificateData = try? Data(contentsOf: URL(fileURLWithPath: path)) as CFData,
            let certificate = SecCertificateCreateWithData(nil, certificateData) else {
        return nil
      }
      return certificate
    }
  }

  var certificates: [SecCertificate] {
    certificates()
  }

  func paths<S: Sequence>(forResourcesOfTypes types: S, inDirectory directory: String? = nil) -> [String] where S.Element == String {
      Array(Set(types.flatMap { paths(forResourcesOfType: $0, inDirectory: directory) }))
  }
}

#endif
