//
//  CoreNetworkingMacrosPlugin.swift
//
//  Created by Waqar Malik on 11/6/26.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// Compiler plugin exposing the CoreNetworking macros.
@main
struct CoreNetworkingMacrosPlugin: CompilerPlugin {
  let providingMacros: [any Macro.Type] = [
    EndpointMacro.self
  ]
}
