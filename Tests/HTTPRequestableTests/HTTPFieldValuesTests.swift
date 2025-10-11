//
//  HTTPFieldValuesTests.swift
//
//
//  Created by Waqar Malik on 5/10/24
//

import Foundation
@testable import HTTPRequestable
import Testing

@Suite("HTTPFieldValues tests")
struct HTTPFieldValuesTests {
  @Test("KeyedItem form-data encoding")
  func keyedItemFormData() async throws {
    let values = KeyedItem(item: "form-data", parameters: ["name": "\"name.png\"", "filename": "\"filename.txt\""])
    #expect(["form-data; name=\"name.png\"; filename=\"filename.txt\"", "form-data; filename=\"filename.txt\"; name=\"name.png\""]
      .contains(values.encoded))
  }

  @Test("KeyedItem boundary encoding")
  func keyedItemBoundary() async throws {
    let boundary = MultipartFormBoundaryType.boundary(forBoundaryType: .initial, boundary: "boundary")
    let values = KeyedItem(item: "multipart/form-data", parameters: ["boundary": boundary])
    #expect(values.encoded == "multipart/form-data; boundary=\(boundary)")
  }

  @Test("Quality encoding")
  func testQuality() async throws {
    let items = [
      Quality.Item(item: "br", parameters: Quality.Parameter(q: 1.0)),
      Quality.Item(item: "gzip", parameters: Quality.Parameter(q: 0.9)),
      Quality.Item(item: "deflate", parameters: Quality.Parameter(q: 0.8))
    ]
    let quality = Quality(items)
    #expect(quality.encoded == "br;q=1.0,gzip;q=0.9,deflate;q=0.8")
  }

  @Test("MultipartForm contentType header encoding")
  func multipartFormBodyHeader() async throws {
    let boundary = "109AF0987D004171B0A8481D6401B62D"
    let multiformData = MultipartForm(boundary: boundary)
    #expect(multiformData.contentType.encoded == "multipart/form-data; boundary=\(boundary)")
  }
}
