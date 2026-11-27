//
//  URLEncoding.swift
//
//  Created by Waqar Malik on 11/23/26.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Percent-encoding used to build request URLs.
///
/// `URLComponents` leaves `+` unencoded in query items, which servers decode as a space, and its `path`
/// setter cannot express a `/` inside a segment. These helpers encode each part on its own instead.
enum URLEncoding {
  /// Characters left as is in a path segment: those allowed in a path, except `/`.
  static let pathSegmentAllowed: CharacterSet = {
    var allowed = CharacterSet.urlPathAllowed
    allowed.remove("/")
    return allowed
  }()

  /// Characters left as is in a query name or value: those allowed in a query, except the separators
  /// `&`, `=` and `;`, and `+`, which form-decoding servers read as a space.
  static let queryComponentAllowed: CharacterSet = {
    var allowed = CharacterSet.urlQueryAllowed
    allowed.remove(charactersIn: "&=;+")
    return allowed
  }()

  /// `segment` percent-encoded for use as one path segment, with `/` encoded as `%2F`.
  static func pathSegment(_ segment: String) -> String {
    // Swift strings are always valid Unicode, so encoding cannot fail.
    segment.addingPercentEncoding(withAllowedCharacters: pathSegmentAllowed) ?? ""
  }

  /// `component` percent-encoded for use as a query name or value.
  static func queryComponent(_ component: String) -> String {
    // Swift strings are always valid Unicode, so encoding cannot fail.
    component.addingPercentEncoding(withAllowedCharacters: queryComponentAllowed) ?? ""
  }

  /// `items` as a percent-encoded query string, without the leading `?`. An item with a `nil` value is
  /// written as its name alone.
  static func query(_ items: [URLQueryItem]) -> String {
    items.map { item in
      let name = queryComponent(item.name)
      return item.value.map { "\(name)=\(queryComponent($0))" } ?? name
    }
    .joined(separator: "&")
  }

  /// Whether the percent-encoded `segment` is `.` or `..` once decoded. Servers and proxies resolve these,
  /// so a request for `/users/../admin` can reach `/admin`.
  static func isDotSegment(_ segment: String) -> Bool {
    let decoded = segment.removingPercentEncoding ?? segment
    return decoded == "." || decoded == ".."
  }

  /// `queries` joined with `&`, leaving out empty ones, or `nil` when none remain.
  static func joinedQuery(_ queries: String?...) -> String? {
    let parts = queries.compactMap(\.self).filter { !$0.isEmpty }
    return parts.isEmpty ? nil : parts.joined(separator: "&")
  }

  /// Whether `url` can be sent as an HTTP request: it has a scheme and a host.
  static func isRequestable(_ url: URL) -> Bool {
    let url = url.absoluteURL
    return url.scheme?.isEmpty == false && url.host?.isEmpty == false
  }
}
