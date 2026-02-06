//
//  QualityEncodedTests.swift
//
//  Created by Waqar Malik on 10/25/24.
//

import Foundation
@testable import HTTPRequestable
import Testing

struct QualityEncodedTests {
  @Test func qualityEncodedLanguageUS() {
    let quality = Quality(values: ["en-US"])
    let encoded = quality.encoded
    #expect(encoded == "en-US;q=1.0")
  }

  @Test func qualityEncodedLanguageEnglish() {
    let quality = Quality(values: ["en-US", "en-GB", "en-AU", "en-CA"])
    let encoded = quality.encoded
    #expect(encoded == "en-US;q=1.0,en-GB;q=0.9,en-AU;q=0.8,en-CA;q=0.7")
  }
}
