import HTTPTypes
@testable import HTTPRequestable
import XCTest

final class HTTPRequestableTests: XCTestCase {
  func testDefaultHeaders() throws {
    // "xctest/14.2 (com.apple.dt.xctest.tool; build:21501; macOS Version 13.1 (Build 22C65)) WebService"
    let userAgent = HTTPField.defaultUserAgent
    XCTAssertEqual(userAgent.name, HTTPField.Name.userAgent)
    XCTAssertEqual(userAgent.value.contains("com.apple.dt.xctest.tool"), true)
    XCTAssertEqual(userAgent.value.hasPrefix("xctest"), true)
    XCTAssertEqual(userAgent.value.hasSuffix("URLRequestable"), true)
    XCTAssertEqual(userAgent.value, String.url_userAgent)
  }
}
