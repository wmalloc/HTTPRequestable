//
//  HTTPFieldNameMacroTests.swift
//
//  Created by Waqar Malik on 11/25/26.
//

#if canImport(HTTPRequestableMacros)
import HTTPRequestableMacros
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

struct HTTPFieldNameMacroTests {
  private let macros: [String: MacroSpec] = ["HTTPFieldName": MacroSpec(type: HTTPFieldNameMacro.self)]

  private func expectExpansion(_ source: String, _ expanded: String,
                               fileID: StaticString = #fileID, filePath: StaticString = #filePath, line: UInt = #line, column: UInt = #column)
  {
    assertMacroExpansion("let name = \(source)", expandedSource: "let name = \(expanded)", macroSpecs: macros,
                         indentationWidth: .spaces(2), failureHandler: recordMacroFailure,
                         fileID: fileID, filePath: filePath, line: line, column: column)
  }

  private func expectRejected(_ source: String, message: String,
                              fileID: StaticString = #fileID, filePath: StaticString = #filePath, line: UInt = #line, column: UInt = #column)
  {
    assertMacroExpansion("let name = \(source)", expandedSource: "let name = \(source)",
                         diagnostics: [DiagnosticSpec(message: message, line: 1, column: 12)],
                         macroSpecs: macros, indentationWidth: .spaces(2), failureHandler: recordMacroFailure,
                         fileID: fileID, filePath: filePath, line: line, column: column)
  }

  // MARK: Accepted

  @Test("Valid field names expand to an unwrapped name", arguments: [
    "X-Request-ID",
    "x-api-key",
    "Content-Type",
    "a",
    "!#$%&'*+-.^_`|~0123456789",
  ])
  func expands(name: String) {
    expectExpansion(#"#HTTPFieldName("\#(name)")"#, #"HTTPField.Name("\#(name)")!"#)
  }

  @Test("Escapes and raw strings expand to the string they represent")
  func escapes() {
    expectExpansion(#"#HTTPFieldName("X-\u{41}")"#, #"HTTPField.Name("X-A")!"#)
    expectExpansion(##"#HTTPFieldName(#"X-Trace"#)"##, #"HTTPField.Name("X-Trace")!"#)
  }

  // MARK: Rejected

  @Test("Interpolation and non-literal arguments are rejected")
  func requiresLiteral() {
    let message = "#HTTPFieldName requires a string literal without interpolation"
    expectRejected(#"#HTTPFieldName("X-\(suffix)")"#, message: message)
    expectRejected("#HTTPFieldName(headerName)", message: message)
    expectRejected("#HTTPFieldName()", message: message)
  }

  @Test("Strings that are not valid field names are rejected", arguments: [
    "",
    "X Request",
    " X-Request",
    "X-Request:",
    ":authority",
    "X-Requést",
    "X-Request\\r\\nInjected",
    "X(Request)",
    "X\\\"Request",
  ])
  func invalid(name: String) {
    expectRejected(#"#HTTPFieldName("\#(name)")"#,
                   message: "#HTTPFieldName requires a valid field name: letters, digits and !#$%&'*+-.^_`|~, without spaces or colons")
  }
}
#endif
