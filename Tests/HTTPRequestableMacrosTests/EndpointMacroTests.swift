//
//  EndpointMacroTests.swift
//
//  Created by Waqar Malik on 11/6/26.
//

#if canImport(HTTPRequestableMacros)
import HTTPRequestableMacros
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing

struct EndpointMacroTests {
  private let macros: [String: MacroSpec] = ["Endpoint": MacroSpec(type: EndpointMacro.self)]

  @Test("Without arguments, adds empty header fields and query items")
  func bareAddsHeaderFieldsAndQueryItems() {
    assertMacroExpansion(
      """
      @Endpoint
      struct ItemsRequest {
      }
      """,
      expandedSource: """
      struct ItemsRequest {

        var headerFields = HTTPFields()

        var queryItems: [URLQueryItem] = []
      }
      """,
      macroSpecs: macros,
      indentationWidth: .spaces(2),
      failureHandler: recordMacroFailure
    )
  }

  @Test("With every argument, adds the method, path, header fields and query items")
  func addsAllMembers() {
    assertMacroExpansion(
      """
      @Endpoint(.post, path: "/api/v1/items", headerFields: [.accept: "application/json"], queryItems: ["limit": "10"])
      struct ItemsRequest {
      }
      """,
      expandedSource: """
      struct ItemsRequest {

        var headerFields: HTTPFields = [.accept: "application/json"]

        var method: HTTPMethod {
          .post
        }

        var path: String {
          "/api/v1/items"
        }

        var queryItems: [URLQueryItem] = [URLQueryItem(name: "limit", value: "10")]
      }
      """,
      macroSpecs: macros,
      indentationWidth: .spaces(2),
      failureHandler: recordMacroFailure
    )
  }

  @Test("A path alone adds no method, so the default GET applies")
  func pathOnlyKeepsDefaultMethod() {
    assertMacroExpansion(
      """
      @Endpoint(path: "/api/v1/items")
      struct ItemsRequest {
      }
      """,
      expandedSource: """
      struct ItemsRequest {

        var headerFields = HTTPFields()

        var path: String {
          "/api/v1/items"
        }

        var queryItems: [URLQueryItem] = []
      }
      """,
      macroSpecs: macros,
      indentationWidth: .spaces(2),
      failureHandler: recordMacroFailure
    )
  }

  @Test("A method alone leaves a hand-written path in place")
  func methodOnlyLeavesHandWrittenPath() {
    assertMacroExpansion(
      """
      @Endpoint(.put)
      struct ItemsRequest {
        var path: String {
          paymentsPath("/v1/items")
        }
      }
      """,
      expandedSource: """
      struct ItemsRequest {
        var path: String {
          paymentsPath("/v1/items")
        }

        var headerFields = HTTPFields()

        var method: HTTPMethod {
          .put
        }

        var queryItems: [URLQueryItem] = []
      }
      """,
      macroSpecs: macros,
      indentationWidth: .spaces(2),
      failureHandler: recordMacroFailure
    )
  }

  @Test("Hand-written query items are kept when queryItems is not passed")
  func keepsHandWrittenQueryItems() {
    assertMacroExpansion(
      """
      @Endpoint
      struct ItemsRequest {
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "limit", value: "10")]
      }
      """,
      expandedSource: """
      struct ItemsRequest {
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "limit", value: "10")]

        var headerFields = HTTPFields()
      }
      """,
      macroSpecs: macros,
      indentationWidth: .spaces(2),
      failureHandler: recordMacroFailure
    )
  }

  @Test("Empty query items add empty storage")
  func emptyQueryItemsAddsEmptyStorage() {
    assertMacroExpansion(
      """
      @Endpoint(queryItems: [:])
      struct ItemsRequest {
      }
      """,
      expandedSource: """
      struct ItemsRequest {

        var headerFields = HTTPFields()

        var queryItems: [URLQueryItem] = []
      }
      """,
      macroSpecs: macros,
      indentationWidth: .spaces(2),
      failureHandler: recordMacroFailure
    )
  }

  @Test("Query items keep their order, duplicate names and nil values")
  func queryItemsKeepOrderDuplicatesAndNil() {
    assertMacroExpansion(
      """
      @Endpoint(queryItems: ["tag": "a", "tag": "b", "flag": nil])
      struct ItemsRequest {
      }
      """,
      expandedSource: """
      struct ItemsRequest {

        var headerFields = HTTPFields()

        var queryItems: [URLQueryItem] = [URLQueryItem(name: "tag", value: "a"), URLQueryItem(name: "tag", value: "b"), URLQueryItem(name: "flag", value: nil)]
      }
      """,
      macroSpecs: macros,
      indentationWidth: .spaces(2),
      failureHandler: recordMacroFailure
    )
  }

  @Test("Query items are built from a dictionary literal")
  func queryItemsFromDictionary() {
    assertMacroExpansion(
      """
      @Endpoint(queryItems: ["limit": "10"])
      struct ItemsRequest {
      }
      """,
      expandedSource: """
      struct ItemsRequest {

        var headerFields = HTTPFields()

        var queryItems: [URLQueryItem] = [URLQueryItem(name: "limit", value: "10")]
      }
      """,
      macroSpecs: macros,
      indentationWidth: .spaces(2),
      failureHandler: recordMacroFailure
    )
  }

  @Test("Query items and a path from constants are accepted")
  func mapsNonLiteralQueryItemsAndAcceptsConstantPath() {
    assertMacroExpansion(
      """
      @Endpoint(path: Constants.path, queryItems: Constants.defaultQuery)
      struct ItemsRequest {
      }
      """,
      expandedSource: """
      struct ItemsRequest {

        var headerFields = HTTPFields()

        var path: String {
          Constants.path
        }

        var queryItems: [URLQueryItem] = Constants.defaultQuery.map {
          URLQueryItem(name: $0.key, value: $0.value)
        }
      }
      """,
      macroSpecs: macros,
      indentationWidth: .spaces(2),
      failureHandler: recordMacroFailure
    )
  }

  @Test("A type that already declares a member the macro adds is rejected", arguments: [
    ("var headerFields = HTTPFields()", "headerFields", "@Endpoint"),
    ("let path: String = \"/api/v2/items\"", "path", "@Endpoint(path: \"/api/v1/items\")"),
    ("var queryItems: [URLQueryItem] = []", "queryItems", "@Endpoint (queryItems: [:])")
  ])
  func rejectsExistingStoredMember(member: String, name: String, attribute: String) {
    assertMacroExpansion(
      """
      \(attribute)
      struct ItemsRequest {
        \(member)
      }
      """,
      expandedSource: """
      struct ItemsRequest {
        \(member)
      }
      """,
      diagnostics: [DiagnosticSpec(message: "@Endpoint cannot be used on a type that already declares '\(name)'", line: 1, column: 1)],
      macroSpecs: macros,
      indentationWidth: .spaces(2),
      failureHandler: recordMacroFailure
    )
  }

  @Test("A type that already declares the method is rejected")
  func rejectsExistingMember() {
    assertMacroExpansion(
      """
      @Endpoint(.post)
      struct ItemsRequest {
        let method: HTTPMethod = .put
      }
      """,
      expandedSource: """
      struct ItemsRequest {
        let method: HTTPMethod = .put
      }
      """,
      diagnostics: [DiagnosticSpec(message: "@Endpoint cannot be used on a type that already declares 'method'", line: 1, column: 1)],
      macroSpecs: macros,
      indentationWidth: .spaces(2),
      failureHandler: recordMacroFailure
    )
  }

  @Test("Enums are rejected")
  func rejectsEnum() {
    assertMacroExpansion(
      """
      @Endpoint
      enum ItemsRequest {}
      """,
      expandedSource: """
      enum ItemsRequest {}
      """,
      diagnostics: [DiagnosticSpec(message: "@Endpoint can only be applied to a struct or class", line: 1, column: 1)],
      macroSpecs: macros,
      indentationWidth: .spaces(2),
      failureHandler: recordMacroFailure
    )
  }

  @Test("Static members with the same name do not conflict")
  func ignoresStaticMembersWithSameName() {
    assertMacroExpansion(
      """
      @Endpoint(path: "/items")
      struct ItemsRequest {
        static let path = "/other"
      }
      """,
      expandedSource: """
      struct ItemsRequest {
        static let path = "/other"

        var headerFields = HTTPFields()

        var path: String {
          "/items"
        }

        var queryItems: [URLQueryItem] = []
      }
      """,
      macroSpecs: macros,
      indentationWidth: .spaces(2),
      failureHandler: recordMacroFailure
    )
  }

  @Test("A package type gets package members")
  func packageTypeGetsPackageMembers() {
    assertMacroExpansion(
      """
      @Endpoint
      package struct ItemsRequest {
      }
      """,
      expandedSource: """
      package struct ItemsRequest {

        package var headerFields = HTTPFields()

        package var queryItems: [URLQueryItem] = []
      }
      """,
      macroSpecs: macros,
      indentationWidth: .spaces(2),
      failureHandler: recordMacroFailure
    )
  }
}
#endif
