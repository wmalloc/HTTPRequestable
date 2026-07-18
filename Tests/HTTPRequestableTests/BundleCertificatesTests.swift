//
//  BundleCertificatesTests.swift
//

import Foundation
@testable import HTTPRequestable
#if canImport(Security)
import Security
#endif
import Testing

@Suite("Bundle Certificates Tests")
struct BundleCertificatesTests {
  @Test("certificateExtensions contains expected file extensions")
  func certificateExtensions() {
    let expected: Set = [".cer", ".CER", ".crt", ".CRT", ".der", ".DER"]
    #expect(Bundle.certificateExtensions == expected)
  }

  @Test("certificates(inDirectory:) returns empty for the test bundle")
  func certificatesEmptyBundle() {
    #expect(Bundle.module.certificates().isEmpty)
  }

  @Test("certificates computed property matches certificates() method")
  func certificatesPropertyMatchesMethod() {
    let bundle = Bundle.module
    #expect(bundle.certificates == bundle.certificates())
  }

  @Test("static certificates(in:inDirectory:) returns empty for a bundle with no certs")
  func staticCertificatesEmpty() {
    let bundle = Bundle.module
    // The test bundle ships no .cer/.crt/.der files, so the result must be empty.
    let certsViaStatic = Bundle.certificates(in: bundle, inDirectory: nil)
    let certsViaInstance = bundle.certificates()
    #expect(certsViaStatic.count == certsViaInstance.count)
  }

  @Test("paths(forResourcesOfTypes:) returns no certificate paths in test bundle")
  func pathsForResourcesOfTypes() {
    let paths = Bundle.module.paths(forResourcesOfTypes: Bundle.certificateExtensions, inDirectory: nil)
    #expect(paths.isEmpty)
  }
}
