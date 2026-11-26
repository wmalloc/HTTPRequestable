//
//  HTTPFieldNameMacro.swift
//
//  Created by Waqar Malik on 11/25/26.
//

import HTTPTypes
import SwiftSyntax
import SwiftSyntaxMacros

/// Implementation of the `#HTTPFieldName` macro.
///
/// Checks the string literal when the code is built and expands to `HTTPField.Name("<literal>")!`. The
/// force unwrap cannot fail: the literal is rejected unless `HTTPField.Name` accepts it here, and the
/// same initializer runs in the app.
public struct HTTPFieldNameMacro: ExpressionMacro {
  public static func expansion(of node: some FreestandingMacroExpansionSyntax,
                               in context: some MacroExpansionContext) throws -> ExprSyntax
  {
    guard node.arguments.count == 1,
          let literal = node.arguments.first?.expression.as(StringLiteralExprSyntax.self),
          let name = literal.representedLiteralValue
    else {
      throw MacroExpansionErrorMessage("#HTTPFieldName requires a string literal without interpolation")
    }
    try validate(name)
    return "HTTPField.Name(\(literal: name))!"
  }

  /// Throws unless `name` is a valid HTTP field name: one or more RFC 9110 token characters.
  ///
  /// Pseudo header fields such as `:authority` are rejected, because `HTTPFields` does not allow them.
  static func validate(_ name: String) throws {
    guard HTTPField.Name(name) != nil else {
      throw MacroExpansionErrorMessage(
        "#HTTPFieldName requires a valid field name: letters, digits and !#$%&'*+-.^_`|~, without spaces or colons"
      )
    }
  }
}
