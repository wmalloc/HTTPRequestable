//
//  EndpointMacro.swift
//
//  Created by Waqar Malik on 11/6/26.
//

import SwiftSyntax
import SwiftSyntaxMacros

/// Implementation of the `@Endpoint` macro.
/// Always adds stored `headerFields`, initialized from `headerFields:` when given. Adds `method`
/// (first unlabeled argument), `path` (`path:`) and stored `queryItems` (`queryItems:`) only when
/// those arguments are passed, so hand-written members can be combined with the macro. Members are
/// `public` when the type is `public` or `open`.
public struct EndpointMacro: MemberMacro {
  public static func expansion(of node: AttributeSyntax,
                               providingMembersOf declaration: some DeclGroupSyntax,
                               conformingTo protocols: [TypeSyntax],
                               in context: some MacroExpansionContext) throws -> [DeclSyntax]
  {
    let arguments = node.arguments?.as(LabeledExprListSyntax.self) ?? []
    let method = arguments.first { $0.label == nil }?.expression
    let path = argument("path", in: arguments)
    let headerFields = argument("headerFields", in: arguments)
    let queryItems = argument("queryItems", in: arguments)

    try declaration.validateStorage(for: "headerFields", macroName: "@Endpoint")
    let access = declaration.memberAccessModifier
    var members = [EndpointMember.headerFields(headerFields, access: access)]

    if let method {
      try declaration.validateStorage(for: "method", macroName: "@Endpoint")
      members.append(EndpointMember.method(method, access: access))
    }
    if let path {
      try declaration.validateStorage(for: "path", macroName: "@Endpoint")
      members.append(EndpointMember.path(path, access: access))
    }
    if let queryItems {
      try declaration.validateStorage(for: "queryItems", macroName: "@Endpoint")
      members.append(EndpointMember.queryItems(queryItems, access: access))
    }
    return members
  }

  /// The expression passed for the labeled argument, if any.
  private static func argument(_ label: String, in arguments: LabeledExprListSyntax) -> ExprSyntax? {
    arguments.first { $0.label?.text == label }?.expression
  }
}
