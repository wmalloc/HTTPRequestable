//
//  EndpointMember.swift
//
//  Created by Waqar Malik on 11/6/26.
//

import SwiftSyntax

/// Builds the members added by `@Endpoint`.
enum EndpointMember {
  /// `var method: HTTPMethod { <method> }`
  static func method(_ method: ExprSyntax, access: String) -> DeclSyntax {
    "\(raw: access)var method: HTTPMethod { \(method.trimmed) }"
  }

  /// `var path: String { <path> }`
  static func path(_ path: ExprSyntax, access: String) -> DeclSyntax {
    "\(raw: access)var path: String { \(path.trimmed) }"
  }

  /// Stored `headerFields`, initialized with fields when given.
  static func headerFields(_ fields: ExprSyntax?, access: String) -> DeclSyntax {
    guard let fields else {
      return "\(raw: access)var headerFields = HTTPFields()"
    }
    return "\(raw: access)var headerFields: HTTPFields = \(fields.trimmed)"
  }

  /// Stored `queryItems`. A dictionary literal expands to `URLQueryItem` values in source order,
  /// keeping duplicate names; any other expression is mapped at runtime. With no items, or an
  /// empty literal, the property starts empty.
  static func queryItems(_ items: ExprSyntax?, access: String) -> DeclSyntax {
    guard let items else {
      return "\(raw: access)var queryItems: [URLQueryItem] = []"
    }
    guard let dictionary = items.as(DictionaryExprSyntax.self) else {
      return "\(raw: access)var queryItems: [URLQueryItem] = \(items.trimmed).map { URLQueryItem(name: $0.key, value: $0.value) }"
    }
    guard let elements = dictionary.content.as(DictionaryElementListSyntax.self), !elements.isEmpty else {
      return "\(raw: access)var queryItems: [URLQueryItem] = []"
    }
    let queryItems = elements
      .map { "URLQueryItem(name: \($0.key.trimmedDescription), value: \($0.value.trimmedDescription))" }
      .joined(separator: ", ")
    return "\(raw: access)var queryItems: [URLQueryItem] = [\(raw: queryItems)]"
  }
}
