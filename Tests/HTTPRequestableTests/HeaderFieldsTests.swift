//
//  HeaderFieldsTests.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 9/25/24.
//

@testable import HTTPRequestable
import HTTPTypes
import Testing

struct HeaderFieldsTests {
  @Test func convertFromRaw() async throws {
    let headers = ["Content-Type": "application/json", "Accept": "application/json"]
    let fields = HTTPFields(rawValue: headers)
    #expect(fields.count == 2)

    let headerFields = fields.rawValue
    #expect(headerFields.count == 2)
    #expect(headers == headerFields)

    let combinedFields = fields.rawValue
    #expect(combinedFields.count == 2)
  }

  @Test func addMultiple() async throws {
    var headers = HTTPFields()
    headers.append(HTTPField(name: .accept, value: "application/json"))
    #expect(headers.count == 1)

    headers.append(HTTPField(name: .accept, value: "any"))
    #expect(headers.count == 2)
  }
}
