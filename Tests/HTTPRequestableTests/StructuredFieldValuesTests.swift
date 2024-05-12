//
//  StructuredFieldValuesTests.swift
//  
//
//  Created by Waqar Malik on 5/10/24.
//

import XCTest
import StructuredFieldValues

struct KeyedItem<ItemType: Codable & Equatable>: Equatable, StructuredFieldValue {
  static var structuredFieldType: StructuredFieldType {
    .item
  }
  
  var item: ItemType
  var parameters: [String: String]
}

struct QualityItem: Equatable, Codable {
  var parameters: [String: Float]
  var item: String
}

struct List<Base: Codable & Equatable>: StructuredFieldValue, Equatable {
  static var structuredFieldType: StructuredFieldType {
    .list
  }
  
  var items: [Base]
  
  init(_ items: [Base]) {
    self.items = items
  }
}

final class StructuredFieldValuesTests: XCTestCase {
  func testKeyedItem() throws {
    let encoder = StructuredFieldValueEncoder()
    let values = KeyedItem(item: "form-data", parameters: ["name": "name.png", "filename": "filename.txt"])
    let encoded = try encoder.encode(values)
    XCTAssertEqual(Array("form-data;name=name.png;filename=filename.txt".utf8), encoded)
  }
  
  func testQuality() throws {
    //"br;q=1.0, gzip;q=0.9, deflate;q=0.8"
    let encoder = StructuredFieldValueEncoder()
    let header = [QualityItem(parameters: ["q": 1.0], item: "br"),
                  QualityItem(parameters: ["q": 0.9], item: "gzip"),
                  QualityItem(parameters: ["q": 0.8], item: "deflate")]
    
    XCTAssertEqual(Array("br;q=1.0, gzip;q=0.9, deflate;q=0.8".utf8),
                   try encoder.encode(List(header))) }
}
