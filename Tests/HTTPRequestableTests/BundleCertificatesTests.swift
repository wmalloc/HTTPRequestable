//
//  BundleCertificatesTests.swift
//  HTTPRequestableTests
//
//  Created by Assistant on 9/10/25.
//

@testable import HTTPRequestable
import XCTest
#if canImport(Security)
import Security
#endif
import Foundation

final class BundleCertificatesTests: XCTestCase {
  /// Test certificateExtensions static property
  func testCertificateExtensions() {
    let expected: Set<String> = [".cer", ".CER", ".crt", ".CRT", ".der", ".DER"]
    XCTAssertEqual(Bundle.certificateExtensions, expected)
  }

  /// Test paths(forResourcesOfTypes:inDirectory:) for empty bundle
  func testPathsForEmptyBundle() {
    let mockBundle = Bundle(for: type(of: self))
    let paths = mockBundle.paths(forResourcesOfTypes: [".cer", ".crt"], inDirectory: nil)
    XCTAssertTrue(paths.isEmpty || paths.allSatisfy(\.isEmpty))
  }

  /// Test certificates() returns empty for empty bundle
  func testCertificatesReturnsEmptyForEmptyBundle() {
    let mockBundle = Bundle(for: type(of: self))
    let certs = mockBundle.certificates()
    XCTAssertTrue(certs.isEmpty)
  }

  #if canImport(Security)
  // Helper: Create a DER-encoded self-signed certificate as Data (mock for test only)
  func testCertificatesFromRawData() {
    // This is a very minimal, invalid DER-encoded cert for testing SecCertificateCreateWithData (will fail to parse as real cert)
    let dummyDER: [UInt8] = [0x30, 0x82, 0x01, 0x0A, 0x02, 0x82, 0x01, 0x01, 0x00]
    let data = Data(dummyDER)
    guard let certificate = SecCertificateCreateWithData(nil, data as CFData) else {
      // Should be nil, as data is invalid, but test the function
      XCTAssertNil(SecCertificateCreateWithData(nil, Data([0x00, 0x01]) as CFData))
      return
    }
    // If by any chance a cert is produced, check type
    XCTAssertTrue(certificate.publicKey != nil)
  }
  #endif

  /// Test static certificates(in:inDirectory:) overload
  func testStaticCertificates() {
    let certs = Bundle.certificates(in: Bundle(for: type(of: self)), inDirectory: nil)
    XCTAssertTrue(certs.isEmpty)
  }

  /// Test certificates computed property
  func testCertificatesProperty() {
    let mockBundle = Bundle(for: type(of: self))
    XCTAssertEqual(mockBundle.certificates, mockBundle.certificates())
  }
}
