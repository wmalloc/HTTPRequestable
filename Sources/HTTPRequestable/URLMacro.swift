//
//  URLMacro.swift
//
//  Created by Waqar Malik on 11/24/26.
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
#endif

/// Creates a `URL` from a string literal that is checked when you build.
///
/// The build fails unless the literal is a valid URL with a scheme and a host, so the result is a plain
/// `URL` that needs no unwrapping and cannot fail when the app runs:
///
/// ```swift
/// let base = #URL("https://api.example.com/v1")
/// let request = URLRequest(url: #URL("https://api.example.com/v1/items"))
/// ```
///
/// The literal is rejected when:
/// - it contains interpolation, because only a literal can be checked when you build;
/// - it is not already a valid URL. Characters such as spaces must be percent-encoded (`%20`), because
///   Foundation versions differ in how they repair them;
/// - it has no scheme or no host;
/// - it contains a user name or password. Requests never send them (see ``HTTPRequestConfigurable/url``),
///   and a secret written in source code ends up in the app binary. Use an `Authorization` header.
///
/// - Parameter string: The URL, as a string literal.
/// - Returns: The URL the literal describes.
@freestanding(expression)
public macro URL(_ string: StaticString) -> URL = #externalMacro(module: "HTTPRequestableMacros", type: "URLMacro")
