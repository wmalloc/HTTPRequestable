//
//  HTTPFieldNameMacro.swift
//
//  Created by Waqar Malik on 11/25/26.
//

import HTTPTypes

/// Creates an `HTTPField.Name` from a string literal that is checked when you build.
///
/// The build fails unless the literal is a valid field name, so the result is a plain `HTTPField.Name`
/// that needs no unwrapping and cannot fail when the app runs:
///
/// ```swift
/// extension HTTPField.Name {
///   static let requestID = #HTTPFieldName("X-Request-ID")
/// }
/// request.headerFields[#HTTPFieldName("X-API-Key")] = apiKey
/// ```
///
/// The literal is rejected when:
/// - it contains interpolation, because only a literal can be checked when you build;
/// - it is empty or contains a character RFC 9110 does not allow in a field name, such as a space,
///   a colon or a non-ASCII character. Pseudo header fields such as `:authority` are rejected because
///   `HTTPFields` does not allow them.
///
/// The name keeps the case it is written in; comparisons ignore case.
///
/// - Parameter name: The field name, as a string literal.
/// - Returns: The field name the literal describes.
@freestanding(expression)
public macro HTTPFieldName(_ name: StaticString) -> HTTPField.Name = #externalMacro(module: "HTTPRequestableMacros", type: "HTTPFieldNameMacro")
