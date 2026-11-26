//
//  FieldValueValidationTests.swift
//
//  Created by Waqar Malik on 11/25/26.
//

import Foundation
@testable import HTTPRequestable
import HTTPTypes
import Testing

struct KeyedItemValidationTests {
  @Test("Without parameters only the item is written")
  func noParameters() throws {
    #expect(try KeyedItem(item: "form-data").encoded == "form-data")
    #expect(try KeyedItem(item: 42, parameters: ["unit": "kg"]).encoded == "42; unit=kg")
  }

  @Test("Parameters are sorted by key")
  func sortedParameters() throws {
    let item = try KeyedItem(item: "x", parameters: ["d": "4", "b": "2", "a": "1", "c": "3"])
    #expect(item.encoded == "x; a=1; b=2; c=3; d=4")
  }

  @Test("A value that is not a token is quoted, so it cannot add parameters", arguments: [
    ("a.txt; evil=1", #""a.txt; evil=1""#),
    ("a b", #""a b""#),
    ("a\tb", "\"a\tb\""),
    (#"say "hi""#, #""say \"hi\"""#),
    (#"back\slash"#, #""back\\slash""#),
    ("", #""""#),
    ("ä.txt", #""ä.txt""#)
  ])
  func quotesNonTokens(value: String, expected: String) throws {
    #expect(try KeyedItem(item: "attachment", parameters: ["filename": value]).encoded == "attachment; filename=\(expected)")
  }

  @Test("Tokens and quoted-strings are kept as they are", arguments: [
    "109AF0987D004171B0A8481D6401B62D",
    #""name.png""#,
    #""a \"b\" c""#,
    #""ä.txt""#
  ])
  func keepsValidValues(value: String) throws {
    #expect(try KeyedItem(item: "attachment", parameters: ["filename": value]).encoded == "attachment; filename=\(value)")
  }

  @Test("Values that only look quoted are quoted again", arguments: [
    (#""a\""#, #""\"a\\\"""#),
    (#""a"b""#, #""\"a\"b\"""#),
    (#"""#, #""\"""#)
  ])
  func requotesBrokenQuotedStrings(value: String, expected: String) throws {
    #expect(try KeyedItem(item: "attachment", parameters: ["filename": value]).encoded == "attachment; filename=\(expected)")
  }

  @Test("Items that are not tokens or media ranges are rejected", arguments: ["", "a b", "form-data; x=1", "a/b/c", "x\r\ny"])
  func rejectsInvalidItems(item: String) {
    #expect(throws: HTTPFieldValueError.invalidItem) {
      try KeyedItem(item: item)
    }
  }

  @Test("Parameter names that are not tokens are rejected", arguments: ["bad key=", "", "a;b", "ä"])
  func rejectsInvalidNames(name: String) {
    #expect(throws: HTTPFieldValueError.invalidParameterName(name)) {
      try KeyedItem(item: "attachment", parameters: [name: "v"])
    }
  }

  @Test("Parameter values with control characters are rejected", arguments: [
    "a\r\nSet-Cookie: s=1", "a\nb", "a\u{0}b", "\"a\rb\"", "a\u{7F}",
  ])
  func rejectsControlCharacters(value: String) {
    #expect(throws: HTTPFieldValueError.invalidParameterValue(name: "filename")) {
      try KeyedItem(item: "attachment", parameters: ["filename": value])
    }
  }

  @Test("Errors leave out the rejected value")
  func errorsOmitValue() {
    let error = #expect(throws: HTTPFieldValueError.self) {
      try KeyedItem(item: "attachment", parameters: ["token": "s3cret\r\n"])
    }
    #expect(error?.description.contains("s3cret") == false)
  }

  @Test("setParameter validates, and leaves the parameters unchanged when it throws")
  func setParameter() throws {
    var item = try KeyedItem(item: "attachment", parameters: ["a": "1"])
    try item.setParameter("x.png", forKey: "filename")
    #expect(item["filename"] == "x.png")

    #expect(throws: HTTPFieldValueError.invalidParameterValue(name: "filename")) {
      try item.setParameter("y\r\n", forKey: "filename")
    }
    #expect(throws: HTTPFieldValueError.invalidParameterName("bad key")) {
      try item.setParameter("v", forKey: "bad key")
    }
    #expect(item.parameters == ["a": "1", "filename": "x.png"])

    try item.setParameter(nil, forKey: "filename")
    #expect(item.encoded == "attachment; a=1")
  }

  @Test("Multipart content headers stay valid for hostile names")
  func multipartContentDisposition() throws {
    let form = MultipartForm(boundary: "B")
    let fields = form.contentHeaders(withName: "a\"; name=\"admin\u{0}", fileName: "x.png\r\nX-Injected: 1")
    let disposition = try #require(fields.first?.value)
    #expect(disposition == #"form-data; filename="x.png%0D%0AX-Injected: 1"; name="a%22; name=%22admin%00""#)
  }
}

struct QualityValidationTests {
  @Test("q-values outside 0...1 are rejected", arguments: [Float(1.5), -1, -0.0001, 1.0001, .nan, .infinity, -.infinity])
  func rejectsInvalidQuality(quality: Float) {
    #expect(throws: HTTPFieldValueError.invalidQuality) {
      try Quality.Parameter(q: quality)
    }
    #expect(throws: HTTPFieldValueError.invalidQuality) {
      try Quality.Parameter(double: Double(quality))
    }
  }

  @Test("q-values are written with at most three decimals", arguments: [
    (Float(1), "1.0"), (0, "0.0"), (0.9, "0.9"), (0.12345, "0.123"), (0.05, "0.05"), (0.00001, "0.0"), (0.9996, "1.0"),
  ])
  func qvalues(quality: Float, expected: String) throws {
    let item = try Quality.Item(item: "gzip", parameters: Quality.Parameter(q: quality))
    #expect(Quality([item]).encoded == "gzip;q=\(expected)")
  }

  @Test("Items without a q-value are written alone")
  func noQuality() throws {
    #expect(try Quality([Quality.Item(item: "gzip")]).encoded == "gzip")
  }

  @Test("Tokens and media ranges are valid items", arguments: ["gzip", "en-US", "*", "text/html", "text/*", "*/*"])
  func validItems(item: String) throws {
    #expect(try Quality([Quality.Item(item: item, parameters: 0.5)]).encoded == "\(item);q=0.5")
  }

  @Test("Items that are not tokens or media ranges are rejected", arguments: [
    "gzip, br;q=1", "a b", "", "text/", "/html", "a/b/c", "x\r\ny", "ä"
  ])
  func rejectsInvalidItems(item: String) {
    #expect(throws: HTTPFieldValueError.invalidItem) {
      try Quality.Item(item: item)
    }
    #expect(throws: HTTPFieldValueError.invalidItem) {
      try Quality(values: ["gzip", item])
    }
  }

  @Test("Literals create q-values")
  func literals() {
    let float: Quality.Parameter = 0.5
    let string: Quality.Parameter = "0.25"
    let none: Quality.Parameter = nil
    #expect(float.q == 0.5)
    #expect(string.q == 0.25)
    #expect(none.q == nil)
  }

  #if os(macOS) || os(Linux)
  @Test("Invalid literals stop the process")
  func invalidLiteralsTrap() async {
    await #expect(processExitsWith: .failure) {
      _ = Quality.Parameter(floatLiteral: 1.5)
    }
    await #expect(processExitsWith: .failure) {
      _ = Quality.Parameter(stringLiteral: "abc")
    }
    await #expect(processExitsWith: .failure) {
      _ = Quality.Parameter(stringLiteral: "2")
    }
  }
  #endif

  @Test("Decoding validates items and q-values")
  func decodingValidates() throws {
    let decoder = JSONDecoder()
    #expect(throws: HTTPFieldValueError.invalidItem) {
      try decoder.decode(Quality.Item.self, from: Data(#"{"item":"gzip, br","parameters":{}}"#.utf8))
    }
    #expect(throws: HTTPFieldValueError.invalidQuality) {
      try decoder.decode(Quality.Item.self, from: Data(#"{"item":"gzip","parameters":{"q":2}}"#.utf8))
    }
    let item = try Quality.Item(item: "gzip", parameters: 0.5)
    #expect(try decoder.decode(Quality.Item.self, from: JSONEncoder().encode(item)) == item)
    let bare = try Quality.Item(item: "gzip")
    #expect(try decoder.decode(Quality.Item.self, from: JSONEncoder().encode(bare)) == bare)
  }

  @Test("Values keep falling by 0.1 up to ten items")
  func tenValues() throws {
    let quality = try Quality(values: (0 ..< 10).map { "l\($0)" })
    #expect(quality.encoded == "l0;q=1.0,l1;q=0.9,l2;q=0.8,l3;q=0.7,l4;q=0.6,l5;q=0.5,l6;q=0.4,l7;q=0.3,l8;q=0.2,l9;q=0.1")
  }

  @Test("Values beyond ten stay above zero and keep their order", arguments: [11, 12, 100, 1000, 5000])
  func manyValues(count: Int) throws {
    let quality = try Quality(values: (0 ..< count).map { "l\($0)" })
    let qvalues = try quality.encoded.split(separator: ",").map { element in
      try #require(Double(element.split(separator: "=").last.map(String.init) ?? ""))
    }
    #expect(qvalues.count == count)
    #expect(qvalues.first == 1)
    #expect(qvalues.allSatisfy { $0 > 0 })
    #expect(zip(qvalues, qvalues.dropFirst()).allSatisfy { $0 >= $1 })
  }

  @Test("Default headers leave out system values that are not valid items")
  func validValuesOf() {
    #expect(Quality(validValuesOf: ["en-US", "bad value", "fr"]).encoded == "en-US;q=1.0,fr;q=0.9")
    #expect(Quality(validValuesOf: ["bad value"]).encoded == "")
  }

  @Test("The default Accept-Encoding header is unchanged")
  func defaultAcceptEncoding() {
    #expect(HTTPField.defaultAcceptEncoding.value == "br;q=1.0,gzip;q=0.9,deflate;q=0.8")
  }
}

struct MultipartBoundaryValidationTests {
  @Test("RFC 2046 boundaries are valid", arguments: [
    "B", UUID().uuidString, "MUTATION-BOUNDARY", "a'()+_,-./:=? b", String(repeating: "x", count: 70)
  ])
  func validBoundaries(boundary: String) {
    #expect(MultipartForm.isValidBoundary(boundary))
  }

  @Test("Other boundaries are invalid", arguments: [
    "", "ends with space ", "a\r\nb", "a;b", "a\"b", "ä", String(repeating: "x", count: 71),
  ])
  func invalidBoundaries(boundary: String) {
    #expect(!MultipartForm.isValidBoundary(boundary))
  }

  @Test("A boundary that is not a token is quoted in Content-Type")
  func quotesBoundary() {
    let form = MultipartForm(boundary: "a b:c")
    #expect(form.contentType.encoded == #"multipart/form-data; boundary="a b:c""#)
  }

  #if os(macOS) || os(Linux)
  @Test("An invalid boundary stops the process")
  func invalidBoundaryTraps() async {
    await #expect(processExitsWith: .failure) {
      _ = MultipartForm(boundary: "a\r\nb")
    }
  }
  #endif
}
