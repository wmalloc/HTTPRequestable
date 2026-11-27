//
//  URLSessionConfigurationTests.swift
//
//  Created by Waqar Malik on 10/25/24.
//

import Foundation
@testable import HTTPRequestable
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct URLSessionConfigurationTests {
  @Test("Default headers set Accept-Encoding, Accept-Language and User-Agent on a configuration")
  func defaultHeaders() {
    let configuration = URLSessionConfiguration.default
    configuration.httpFields = .defaultHeaders
    let headers = configuration.httpAdditionalHeaders
    #expect(headers != nil)
    #expect(headers?.count == 3)

    let defaultAcceptEncoding = headers?["Accept-Encoding"] as? String
    #expect(defaultAcceptEncoding != nil)
    #expect(defaultAcceptEncoding == "br;q=1.0,gzip;q=0.9,deflate;q=0.8")

    // The languages depend on the machine, so compare with the default header rather than a fixed value.
    let defaultAcceptLang = headers?["Accept-Language"] as? String
    #expect(defaultAcceptLang == HTTPField.defaultAcceptLanguage.value)
    #expect(defaultAcceptLang?.isEmpty == false)

    let defaultUserAgent = headers?["User-Agent"] as? String
    #expect(defaultUserAgent != nil)
  }

  @Test("Accept-Language lists up to six preferred languages, or * when there are none", arguments: [
    ([String](), "*"),
    (["bad value"], "*"),
    (["en-US", "fr"], "en-US;q=1.0,fr;q=0.9"),
    (["a", "b", "c", "d", "e", "f", "g"], "a;q=1.0,b;q=0.9,c;q=0.8,d;q=0.7,e;q=0.6,f;q=0.5"),
  ])
  func acceptLanguage(languages: [String], expected: String) {
    #expect(HTTPField.acceptLanguageValue(for: languages) == expected)
  }
}
