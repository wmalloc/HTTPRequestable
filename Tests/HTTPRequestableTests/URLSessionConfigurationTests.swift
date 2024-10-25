//
//  URLSessionConfigurationTests.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 10/25/24.
//

import Foundation
@testable import HTTPRequestable
import Testing

struct URLSessionConfigurationTests {
  @Test func defaultHeaders() async throws {
    let configuration = URLSessionConfiguration.default
    configuration.httpFields = .defaultHeaders
    let headers = configuration.httpAdditionalHeaders
    #expect(headers != nil)
    #expect(headers?.count == 3)

    let defaultAcceptEncoding = headers?["Accept-Encoding"] as? String
    #expect(defaultAcceptEncoding != nil)
    #expect(defaultAcceptEncoding == "br;q=1.0,gzip;q=0.9,deflate;q=0.8")

    let defaultAcceptLang = headers?["Accept-Language"] as? String
    #expect(defaultAcceptLang != nil)
    #expect(defaultAcceptLang == "en-US;q=1.0")

    let defaultUserAgent = headers?["User-Agent"] as? String
    #expect(defaultUserAgent != nil)
    #expect(defaultUserAgent == "xctest/16.0 (com.apple.dt.xctest.tool; build:23504; iOS(Simulator) Version 18.0 (Build 22A3351)) HTTPRequestable")
  }
}
