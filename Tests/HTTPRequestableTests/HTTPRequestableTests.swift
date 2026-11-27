//
//  HTTPRequestableTests.swift
//
//  Created by Waqar Malik on 1/29/23.
//

@testable import HTTPRequestable
import HTTPTypes
import Testing

struct HTTPRequestableTests {
  @Test("The default User-Agent names HTTPRequestable")
  func defaultHeaders() {
    let userAgent = HTTPField.defaultUserAgent
    #expect(userAgent.name == HTTPField.Name.userAgent)
    #expect(userAgent.value.hasSuffix("HTTPRequestable"))
    #expect(userAgent.value == String.url_userAgent)
  }

  @Test("The User-Agent names the operating system")
  func osName() {
    #if os(macOS)
    #expect(String.url_osName == "macOS")
    #elseif os(Android)
    #expect(String.url_osName == "Android")
    #elseif os(Linux)
    #expect(String.url_osName == "Linux")
    #endif
    #expect(String.url_userAgent.contains(String.url_osName))
  }
}
