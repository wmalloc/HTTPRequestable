//
//  File.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 10/16/25.
//

import Foundation
import HTTPTypes
import HTTPTypesFoundation


public extension HTTPRequestConfigurable {
  /// Appends an HTTP header field to the request's header collection, preserving any existing headers.
  /// 
  /// - Parameter field: The `HTTPField` to append. If a header with the same name already exists,
  ///   this method will add another instance of the header rather than replacing it, which is useful
  ///   for headers that support multiple values (e.g., `Set-Cookie`).
  /// - Returns: A new instance of `Self` with the updated `headerFields`.
  /// - Note: If the receiver currently has no `headerFields`, a new `HTTPFields` collection is created.
  /// - SeeAlso: `set(headerField:)` for replacing the value of a header field.
  func append(headerField field: HTTPField) -> Self {
    var fields = self.headerFields ?? HTTPFields()
    fields.append(field)
    var updated = self
    updated.headerFields = fields
    return updated
  }
  
  /// Sets or replaces an HTTP header field in the request's header collection.
  ///
  /// - Parameter field: The `HTTPField` to set. If a header with the same name already exists,
  ///   its value is replaced with the provided field's value; otherwise, the header is added.
  /// - Returns: A new instance of `Self` with the updated `headerFields`.
  /// - Note: If the receiver currently has no `headerFields`, a new `HTTPFields` collection is created.
  /// - SeeAlso: `append(headerField:)` to add another instance of a header without replacing existing values.
  func set(headerField field: HTTPField) -> Self {
    var fields = self.headerFields ?? HTTPFields()
    fields[field.name] = field.value
    var updated = self
    updated.headerFields = fields
    return updated
  }
}

public extension HTTPRequestConfigurable {
  /// Appends a single URL query item to the request’s existing query items, preserving any existing items.
  ///
  /// - Parameter queryItem: The `URLQueryItem` to append to the request.
  /// - Returns: A new instance of `Self` with the updated `queryItems` array.
  /// - Note: If the receiver currently has no `queryItems`, a new array is created and the item is added.
  /// - SeeAlso: Consider providing an overload to append multiple query items for batch updates.
  func append(queryItem: URLQueryItem) -> Self {
    var queryItems = self.queryItems ?? []
    queryItems.append(queryItem)
    var updated = self
    updated.queryItems = queryItems
    return updated
  }
}
