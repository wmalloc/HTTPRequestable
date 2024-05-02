import HTTPTypes
@testable import URLRequestable
import XCTest

final class URLRequestableTests: XCTestCase {
  func testDefaultHeaders() throws {
    let acceptEncoding = HTTPField.defaultAcceptEncoding
    XCTAssertEqual(acceptEncoding.name, HTTPField.Name.acceptEncoding)
    XCTAssertEqual(acceptEncoding.value, "br;q=1.0, gzip;q=0.9, deflate;q=0.8")

    // "xctest/14.2 (com.apple.dt.xctest.tool; build:21501; macOS Version 13.1 (Build 22C65)) WebService"
    let userAgent = HTTPField.defaultUserAgent
    XCTAssertEqual(userAgent.name, HTTPField.Name.userAgent)
    XCTAssertEqual(userAgent.value.contains("com.apple.dt.xctest.tool"), true)
    XCTAssertEqual(userAgent.value.hasPrefix("xctest"), true)
    XCTAssertEqual(userAgent.value.hasSuffix("URLRequestable"), true)
    XCTAssertEqual(userAgent.value, String.url_userAgent)

    let acceptLanguage = HTTPField.defaultAcceptLanguage
    XCTAssertEqual(acceptLanguage.name, HTTPField.Name.acceptLanguage)
    let lanugages = Locale.preferredLanguages.prefix(6).url_qualityEncoded()
    XCTAssertEqual(acceptLanguage.value, lanugages)
  }
}
