//
//  URLMacro.swift
//
//  Created by Waqar Malik on 11/24/26.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

/// Implementation of the `#URL` macro.
///
/// Checks the string literal when the code is built and expands to `URL(string: "<literal>")!`. The
/// force unwrap cannot fail: the literal is rejected unless it parses without Foundation repairing any
/// characters, so every Foundation version parses it the same way.
public struct URLMacro: ExpressionMacro {
  public static func expansion(of node: some FreestandingMacroExpansionSyntax,
                               in context: some MacroExpansionContext) throws -> ExprSyntax {
    guard node.arguments.count == 1,
          let literal = node.arguments.first?.expression.as(StringLiteralExprSyntax.self),
          let string = literal.representedLiteralValue
    else {
      throw MacroExpansionErrorMessage("#URL requires a string literal without interpolation")
    }
    try validate(string)
    return "URL(string: \(literal: string))!"
  }

  /// Throws unless `string` is a valid URL with a scheme and a host and without user info.
  ///
  /// Messages leave the literal out, so a rejected password is not repeated in build logs.
  static func validate(_ string: String) throws {
    guard let url = URL(string: string, encodingInvalidCharacters: false) else {
      throw MacroExpansionErrorMessage("#URL requires a valid URL; percent-encode characters such as spaces")
    }
    guard url.scheme?.isEmpty == false, url.host(percentEncoded: true)?.isEmpty == false else {
      throw MacroExpansionErrorMessage("#URL requires a scheme and a host, for example \"https://api.example.com\"")
    }
    guard url.user(percentEncoded: true) == nil, url.password(percentEncoded: true) == nil else {
      throw MacroExpansionErrorMessage("#URL must not contain a user name or password; requests never send them. Use an Authorization header")
    }
  }
}
