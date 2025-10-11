//
//  MultiformDataTests.swift
//
//
//  Created by Waqar Malik on 1/29/23.
//

import Foundation
@testable import HTTPRequestable
import MockURLProtocol
import Testing

@Suite("MultiformDataTests")
struct MultiformDataTests {
  @Test func testBoundary() async throws {
    let boundary = UUID().uuidString.replacingOccurrences(of: "-", with: "")
    let multipartData = MultipartForm(boundary: boundary)
    #expect(boundary == multipartData.boundary)
    let initialBoudary = "--\(boundary)\(EncodingCharacters.crlf)"
    #expect(multipartData.initialBoundary == initialBoudary)
    #expect(multipartData.initialBoundaryData == Data(initialBoudary.utf8))
    let interstitialBoudary = "\(EncodingCharacters.crlf)--\(boundary)\(EncodingCharacters.crlf)"
    #expect(multipartData.interstitialBoundary == interstitialBoudary)
    #expect(multipartData.interstitialBoundaryData == Data(interstitialBoudary.utf8))
    let finalBoundary = "\(EncodingCharacters.crlf)--\(boundary)--\(EncodingCharacters.crlf)"
    #expect(multipartData.finalBoundary == finalBoundary)
    #expect(multipartData.finalBoundaryData == Data(finalBoundary.utf8))
  }

  @Test func oneItem() async throws {
    let boundary = "109AF0987D004171B0A8481D6401B62D"
    let profileDataString = "{\"familyName\": \"Malik\", \"givenName\": \"Waqar\"}"
    let profileData = try #require(profileDataString.data(using: .utf8))
    let multiformData = MultipartForm(boundary: boundary)
    multiformData.append(data: profileData, withName: "\"Profile\"", mimeType: HTTPContentType.json.rawValue)
    let imageDataString = "{\"homePage\": \"https://www.apple.com\"}"
    let imageString = try #require(imageDataString.data(using: .utf8)?.base64EncodedData())
    multiformData.append(data: imageString, withName: "\"Image\"", mimeType: "application/jpeg;base64")
    let encoedData = try multiformData.encoded()
    let data = try Bundle.module.data(forResource: "MultipartFormData", withExtension: "txt")
    #expect(data == encoedData)
  }
}
