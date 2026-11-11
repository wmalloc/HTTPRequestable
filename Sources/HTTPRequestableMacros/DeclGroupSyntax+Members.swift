//
//  DeclGroupSyntax+Members.swift
//
//  Created by Waqar Malik on 11/6/26.
//

import SwiftSyntax
import SwiftSyntaxMacros

extension DeclGroupSyntax {
  /// The access modifier for a member added by a macro: `public` when the type is `public` or
  /// `open`, otherwise empty.
  var memberAccessModifier: String {
    let isPublic = modifiers.contains { modifier in
      modifier.name.tokenKind == .keyword(.public) || modifier.name.tokenKind == .keyword(.open)
    }
    return isPublic ? "public " : ""
  }

  /// Throws unless the declaration is a struct or class that does not already declare `name`.
  /// - Parameters:
  ///   - name: The stored property the macro adds.
  ///   - macroName: The macro name used in diagnostics, e.g. `@Endpoint`.
  func validateStorage(for name: String, macroName: String) throws {
    guard self.is(StructDeclSyntax.self) || self.is(ClassDeclSyntax.self) else {
      throw MacroExpansionErrorMessage("\(macroName) can only be applied to a struct or class")
    }
    if declaresVariable(named: name) {
      throw MacroExpansionErrorMessage("\(macroName) cannot be used on a type that already declares '\(name)'")
    }
  }

  /// Whether the decleration has a variable member binding `name`.
  func declaresVariable(named name: String) -> Bool {
    memberBlock.members.contains { $0.declaresVariable(named: name) }
  }
}

extension MemberBlockItemSyntax {
  /// Whether the member is a variable declaration binding `name`.
  func declaresVariable(named name: String) -> Bool {
    guard let variable = decl.as(VariableDeclSyntax.self) else {
      return false
    }
    return variable.bindings.contains { binding in
      binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == name
    }
  }
}
