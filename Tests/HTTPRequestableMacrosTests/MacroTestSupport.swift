//
//  MacroTestSupport.swift
//
//  Created by Waqar Malik on 11/6/26.
//

#if canImport(HTTPRequestableMacros)
import SwiftSyntaxMacrosGenericTestSupport
import Testing

/// Reports a macro expansion mismatch as a Swift Testing issue at the failing location.
func recordMacroFailure(_ failure: TestFailureSpec) {
  Issue.record(
    Comment(rawValue: failure.message),
    sourceLocation: SourceLocation(fileID: failure.location.fileID,
                                   filePath: failure.location.filePath,
                                   line: failure.location.line,
                                   column: failure.location.column)
  )
}
#endif
