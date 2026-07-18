//
//  MultiformDataTests.swift
//
//  Created by Waqar Malik on 1/29/23.
//

import Foundation
@testable import HTTPRequestable
import MockURLProtocol
import Testing

@Suite("MultipartForm Tests")
struct MultiformDataTests {
  @Test("Boundary strings encode to correct RFC 7578 delimiter format")
  func boundaryEncoding() {
    let boundary = UUID().uuidString
    let multipartData = MultipartForm(boundary: boundary)
    #expect(boundary == multipartData.boundary)

    let initial = "--\(boundary)\r\n"
    #expect(boundary.initialBoundary == initial)
    #expect(boundary.initialBoundaryData == Data(initial.utf8))

    let interstitial = "\r\n--\(boundary)\r\n"
    #expect(boundary.interstitialBoundary == interstitial)
    #expect(boundary.interstitialBoundaryData == Data(interstitial.utf8))

    let final = "\r\n--\(boundary)--\r\n"
    #expect(boundary.finalBoundary == final)
    #expect(boundary.finalBoundaryData == Data(final.utf8))
  }

  @Test("Encoding two parts produces output matching the stored fixture")
  func twoPartEncodingMatchesFixture() throws {
    let boundary = "109AF0987D004171B0A8481D6401B62D"
    let profileData = try #require("{\"familyName\": \"Malik\", \"givenName\": \"Waqar\"}".data(using: .utf8))
    let form = MultipartForm(boundary: boundary)
    form.append(data: profileData, withName: "\"Profile\"", mimeType: HTTPContentType.json.rawValue)

    let imageDataString = "{\"homePage\": \"https://www.apple.com\"}"
    let imageData = try #require(imageDataString.data(using: .utf8)?.base64EncodedData())
    form.append(data: imageData, withName: "\"Image\"", mimeType: "application/jpeg;base64")

    let encoded = try form.data(streamBufferSize: form.streamBufferSize)
    let fixture = try Bundle.module.data(forResource: "MultipartFormData", withExtension: "txt")
    #expect(encoded == fixture)
  }

  @Test("data() does not mutate the form's headers")
  func dataDoesNotMutateHeaders() throws {
    let form = MultipartForm(boundary: "MUTATION-BOUNDARY")
    let payload = Data("hello".utf8)
    form.append(data: payload, withName: "greeting", mimeType: HTTPContentType.textPlain.rawValue)
    let headerCountBefore = form.headers.count
    _ = try form.data(streamBufferSize: form.streamBufferSize)
    #expect(form.headers.count == headerCountBefore)
  }

  @Test("data() and write(encodedDataTo:) produce identical bytes")
  func dataAndWriteConsistency() throws {
    func makeForm() -> MultipartForm {
      let form = MultipartForm(boundary: "CONSISTENCY-BOUNDARY")
      form.append(data: Data("{\"key\":\"value\"}".utf8), withName: "field", mimeType: HTTPContentType.json.rawValue)
      return form
    }

    let inMemory = try makeForm().data(streamBufferSize: 1024)

    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: tempURL) }
    try makeForm().write(encodedDataTo: tempURL, streamBufferSize: 1024)
    let fromDisk = try Data(contentsOf: tempURL)

    #expect(inMemory == fromDisk)
  }

  @Test("contentLength reflects sum of appended body-part byte counts")
  func contentLength() throws {
    let form = MultipartForm(boundary: "LENGTH-BOUNDARY")
    let a = try #require("abc".data(using: .utf8))
    let b = try #require("defgh".data(using: .utf8))
    form.append(data: a, withName: "a")
    form.append(data: b, withName: "b")
    #expect(form.contentLength == UInt64(a.count + b.count))
  }

  @Test("append(stream:withLength:headers:) adds a body part")
  func appendStream() {
    let form = MultipartForm(boundary: "STREAM-BOUNDARY")
    #expect(form.bodyParts.isEmpty)
    let data = Data("test".utf8)
    let stream = InputStream(data: data)
    form.append(stream: stream, withLength: UInt64(data.count), headers: [])
    #expect(form.bodyParts.count == 1)
  }
}
