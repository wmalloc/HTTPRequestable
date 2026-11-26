//
//  URLMacroTests.swift
//
//  Created by Waqar Malik on 11/24/26.
//

#if canImport(HTTPRequestableMacros)
import HTTPRequestableMacros
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

struct URLMacroTests {
  private let macros: [String: MacroSpec] = ["URL": MacroSpec(type: URLMacro.self)]

  private func expectExpansion(_ source: String, _ expanded: String,
                               fileID: StaticString = #fileID, filePath: StaticString = #filePath, line: UInt = #line, column: UInt = #column)
  {
    assertMacroExpansion("let url = \(source)", expandedSource: "let url = \(expanded)", macroSpecs: macros,
                         indentationWidth: .spaces(2), failureHandler: recordMacroFailure,
                         fileID: fileID, filePath: filePath, line: line, column: column)
  }

  private func expectRejected(_ source: String, message: String,
                              fileID: StaticString = #fileID, filePath: StaticString = #filePath, line: UInt = #line, column: UInt = #column)
  {
    assertMacroExpansion("let url = \(source)", expandedSource: "let url = \(source)",
                         diagnostics: [DiagnosticSpec(message: message, line: 1, column: 11)],
                         macroSpecs: macros, indentationWidth: .spaces(2), failureHandler: recordMacroFailure,
                         fileID: fileID, filePath: filePath, line: line, column: column)
  }

  // MARK: Accepted

  @Test("Valid URLs expand to an unwrapped URL", arguments: [
    "https://api.example.com/v1",
    "http://localhost:8080/health",
    "https://api.example.com/v1/items?q=a%20b&sig=abc%2Bdef#section",
    "https://[::1]:8443/",
  ])
  func expands(url: String) {
    expectExpansion(#"#URL("\#(url)")"#, #"URL(string: "\#(url)")!"#)
  }

  @Test("Escapes and raw strings expand to the string they represent")
  func escapes() {
    expectExpansion(#"#URL("https://api.example.com/\u{61}")"#, #"URL(string: "https://api.example.com/a")!"#)
    expectExpansion(##"#URL(#"https://api.example.com/v1"#)"##, #"URL(string: "https://api.example.com/v1")!"#)
  }

  // MARK: Rejected

  @Test("Interpolation and non-literal arguments are rejected")
  func requiresLiteral() {
    let message = "#URL requires a string literal without interpolation"
    expectRejected(#"#URL("https://\(host)/v1")"#, message: message)
    expectRejected("#URL(baseURLString)", message: message)
    expectRejected("#URL()", message: message)
  }

  @Test("Strings that are not already valid URLs are rejected", arguments: [
    "https://api.example.com/a b",
    " https://api.example.com",
    "https://api.example.com/ä",
    "",
  ])
  func invalid(url: String) {
    expectRejected(#"#URL("\#(url)")"#, message: "#URL requires a valid URL; percent-encode characters such as spaces")
  }

  @Test("URLs without a scheme or host are rejected", arguments: [
    "api.example.com/v1",
    "/v1/items",
    "https:/items",
    "https://",
    "mailto:someone@example.com",
    "file:///tmp/data",
  ])
  func requiresSchemeAndHost(url: String) {
    expectRejected(#"#URL("\#(url)")"#, message: #"#URL requires a scheme and a host, for example "https://api.example.com""#)
  }

  @Test("User info is rejected without repeating it in the message", arguments: [
    "https://alice:s3cret@api.example.com/v1",
    "https://alice@api.example.com",
  ])
  func rejectsUserInfo(url: String) {
    let message = "#URL must not contain a user name or password; requests never send them. Use an Authorization header"
    #expect(!message.contains("s3cret") && !message.contains("alice"))
    expectRejected(#"#URL("\#(url)")"#, message: message)
  }
}
#endif
