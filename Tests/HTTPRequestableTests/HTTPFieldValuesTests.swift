//
//  HTTPFieldValuesTests.swift
//
//
//  Created by Waqar Malik on 5/10/24.
//

@testable import MultipartForm
import XCTest

final class StructuredFieldValuesTests: XCTestCase {
  func testKeyedItemFormData() throws {
    let values = KeyedItem(item: "form-data", parameters: ["name": "\"name.png\"", "filename": "\"filename.txt\""])
    XCTAssertTrue(["form-data; name=name.png; filename=\"filename.txt\"", "form-data; filename=\"filename.txt\"; name=\"name.png\""].contains(values.encoded))
  }

  func testKeyedItemBoundary() throws {
    let boundary = MultipartFormBoundaryType.boundary(forBoundaryType: .initial, boundary: "boundary")
    let values = KeyedItem(item: "multipart/form-data", parameters: ["boundary": boundary])
    XCTAssertEqual("multipart/form-data; boundary=\(boundary)", values.encoded)
  }

  func testQuality() {
    // "br;q=1.0, gzip;q=0.9, deflate;q=0.8"
    var quality: Quality {
      let items = [
        Quality.Item(item: "br", parameters: Quality.Parameter(q: 1.0)),
        Quality.Item(item: "gzip", parameters: Quality.Parameter(q: 0.9)),
        Quality.Item(item: "deflate", parameters: Quality.Parameter(q: 0.8)),
      ]
      return Quality(items)
    }
    XCTAssertEqual(quality.encoded, "br;q=1.0,gzip;q=0.9,deflate;q=0.8")
  }

  func testMultipartFormBodyHeader() throws {
    let boundary = "109AF0987D004171B0A8481D6401B62D"
    let multiformData = MultipartForm(boundary: boundary)
    XCTAssertEqual("multipart/form-data; boundary=\(boundary)", multiformData.contentType.encoded)
  }
}
