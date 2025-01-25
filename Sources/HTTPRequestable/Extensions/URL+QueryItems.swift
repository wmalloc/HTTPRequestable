//
//  URL+QueryItems.swift
//
//  Created by Waqar Malik on 5/28/20.
//

import Foundation

/// Extension providing a method for appending query items to an existing URL.
public extension URL {
  /// Appends new query items to the current URL, returning a new `URL` object with the updated query parameters.
  /// - Parameter newItems: An array of `URLQueryItem` instances representing the new query items to append.
  /// - Returns: A new `URL` instance with the appended query items. If the operation fails (e.g., due to invalid input), the original URL is returned unchanged.
  func appendQueryItems(_ newItems: [URLQueryItem]) -> Self {
    var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
    components = components?.appendQueryItems(newItems)
    return components?.url ?? self
  }

  /// Returns a new `URL` instance with all query items removed, if possible.
  /// - Returns: A new `URL` instance without any query items. If the operation fails (e.g., due to invalid input), the original URL is returned unchanged.
  var byRemovingQueryItems: URL {
    guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
      return self
    }
    components.queryItems = nil
    return components.url ?? self
  }
}
