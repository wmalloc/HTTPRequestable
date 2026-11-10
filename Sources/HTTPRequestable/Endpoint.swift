//  Endpoint.swift
//
//  Created by Waqar Malik on 11/6/26.
//

import Foundation
import HTTPTypes

/// Declares an `HTTPRequestConfigurable` endpoint's method, path, headers and query items.
///
/// Always adds stored `headerFields`, initialized from `headerFields`. Adds the other members only
/// when their argument is passed, so a hand-written `method`, `path` or `queryItems` (e.g. one built
/// from the request's inputs) can be combined with the macro:
///
/// - `method` -> `var method: HTTPMethod { <method> }`; omitted, the protocol default `.get` applies.
/// - `path`: -> `var path: String { <path> }`; must be a constant.
/// - `queryItems`: -> stored `var queryItems: [URLQueryItem]` in source order, keeping duplicate
///   names. Pass `[:]` for settable storage that starts empty.
///
/// Members are `public` when the type is `public` or `open`.
///
/// ```swift
/// @Endpoint(.post, path: "/api/v1/items", headerFields: [.accept: "application/json"])
/// struct CreateItemRequest: HTTPRequestConfigurable {
///     typealias ResponseType = Item
///     let environment: HTTPEnvironment
/// }
/// ```
///
/// - Parameters:
///   - method: The HTTP method of the request.
///   - path: The endpoint path, appended to the environment's path.
///   - headerFields: The initial header fields.
///   - queryItems: The initial query item names and values.
@attached(member, names: named(headerFields), named(method), named(path), named(queryItems))
public macro Endpoint(_ method: HTTPMethod = .get,
                      path: String = "",
                      headerFields: HTTPFields = [:],
                      queryItems: KeyValuePairs<String, String?> = [:]) = #externalMacro(module: "HTTPRequestableMacros", type: "EndpointMacro")
