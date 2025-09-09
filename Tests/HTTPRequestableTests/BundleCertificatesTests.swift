import Foundation
@testable import HTTPRequestable
import XCTest
#if canImport(Security)
@preconcurrency import Security
#endif

final class BundleCertificatesTests: XCTestCase {
  func testCertificateExtensions() {
    let expectedExtensions: Set<String> = [".cer", ".CER", ".crt", ".CRT", ".der", ".DER"]
    XCTAssertEqual(Bundle.certificateExtensions, expectedExtensions)
  }

  func testCertificatesInBundle() {
    let bundle = Bundle(for: Self.self)
    let certificates = Bundle.certificates(in: bundle)
    XCTAssertNotNil(certificates)
    XCTAssertTrue(certificates.isEmpty) // Adjust this based on test resources
  }

  func testCertificatesInDirectory() {
    let bundle = Bundle(for: Self.self)
    let certificates = bundle.certificates(inDirectory: "TestCertificates")
    XCTAssertNotNil(certificates)
    XCTAssertTrue(certificates.isEmpty) // Adjust this based on test resources
  }

  func testPathsForResourcesOfTypes() {
    let bundle = Bundle(for: Self.self)
    let paths = bundle.paths(forResourcesOfTypes: ["cer", "crt"], inDirectory: nil)
    XCTAssertNotNil(paths)
    XCTAssertTrue(paths.isEmpty) // Adjust this based on test resources
  }
}
