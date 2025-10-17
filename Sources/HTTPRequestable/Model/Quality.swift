//
//  Quality.swift
//
//
//  Created by Waqar Malik on 5/18/24
//

import Foundation

// "br;q=1.0, gzip;q=0.9, deflate;q=0.8"
/// A type representing a list of items with associated quality values (q-values),
/// commonly used in HTTP header fields for content negotiation (such as `Accept-Encoding`).
///
/// The `Quality` struct holds an array of `Item` values, where each `Item`
/// represents a header value and its optional q-value parameter. The q-value
/// represents a preference (where higher values are preferred).
///
/// Example (as used in HTTP headers):
///     "br;q=1.0, gzip;q=0.9, deflate;q=0.8"
///
/// - Note: Conforms to `Hashable`, `Sendable`, `ExpressibleByArrayLiteral`,
///   and `MutableCollection`.
///
/// Usage:
/// ```swift
/// let quality: Quality = [
///   .init(item: "br", parameters: .init(q: 1.0)),
///   .init(item: "gzip", parameters: .init(q: 0.9)),
///   .init(item: "deflate", parameters: .init(q: 0.8))
/// ]
/// print(quality.encoded) // "br;q=1.0,gzip;q=0.9,deflate;q=0.8"
/// ```
///
/// - SeeAlso: `Quality.Item`, `Quality.Parameter`
@frozen
public struct Quality: Hashable, Sendable {
  public var items: [Item]

  public init(_ items: [Item]) {
    self.items = items
  }

  /// Represents an individual value within a `Quality` list,
  /// such as an encoding or media type and its associated parameters.
  ///
  /// Each `Item` consists of:
  /// - `item`: The string value, e.g., an encoding ("gzip") or media type.
  /// - `parameters`: A `Parameter` instance describing the associated q-value
  ///    (quality factor, a `Float` from 0.0 to 1.0) or other extension parameters.
  ///
  /// Items are commonly used in HTTP content negotiation headers (e.g.,
  /// "Accept-Encoding", "Accept-Language"), where each value can include a
  /// "q" parameter to indicate client/server preference or priority.
  ///
  /// Example usage:
  /// ```swift
  /// let item = Quality.Item(item: "gzip", parameters: .init(q: 0.9))
  /// ```
  ///
  /// - SeeAlso: `Quality`, `Quality.Parameter`
  @frozen
  public struct Item: Codable, Hashable, Sendable {
    public let item: String
    public let parameters: Parameter

    public init(item: String, parameters: Parameter) {
      self.item = item
      self.parameters = parameters
    }
  }

  /// Represents the parameters associated with a `Quality.Item`, most commonly
  /// the optional "q" (quality factor) value used in HTTP content negotiation.
  ///
  /// - `q`: An optional `Float` representing the quality value (between 0.0 and 1.0)
  ///   for the associated item. If `nil`, the q-value is omitted, indicating a default
  ///   preference.
  ///
  /// `Parameter` is used to describe the preference weighting or priority for a value
  /// in HTTP headers such as "Accept-Encoding" or "Accept-Language". It may be further
  /// extended to support additional custom parameters, though the primary use is for
  /// the `q` value.
  ///
  /// Example:
  /// ```swift
  /// let param = Quality.Parameter(q: 0.8)
  /// // Represents a weighting of 0.8 for the associated item.
  /// ```
  ///
  /// - SeeAlso: `Quality.Item`
  @frozen
  public struct Parameter: Codable, Hashable, Sendable {
    // swiftlint:disable identifier_name
    public let q: Float?

    public init(q: Float? = nil) {
      self.q = q
    }

    public init(double: Double) {
      self.q = Float(double)
    }
    // swiftlint:enable identifier_name
  }

  public var encoded: String {
    items.map { item in
      var string = item.item
      if let quality = item.parameters.q {
        string += ";q=\(quality)"
      }
      return string
    }
    .joined(separator: ",")
  }
}

extension Quality: ExpressibleByArrayLiteral {
  public init(arrayLiteral elements: Item...) {
    self.init(elements)
  }
}

extension Quality: MutableCollection {
  public typealias Index = [Item].Index
  public typealias Element = Quality.Item

  public var startIndex: Index {
    items.startIndex
  }

  public var endIndex: Index {
    items.endIndex
  }

  public func index(after index: Index) -> Index {
    items.index(after: index)
  }

  public subscript(position: Index) -> Element {
    get { items[position] }
    set { items[position] = newValue }
  }
}

extension Quality.Parameter: ExpressibleByFloatLiteral {
  public init(floatLiteral value: Float) {
    self.init(q: value)
  }
}

extension Quality.Parameter: ExpressibleByNilLiteral {
  public init(nilLiteral: ()) {
    self.init(q: nil)
  }
}

extension Quality.Parameter: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self.init(q: Float(value))
  }
}

extension Quality: CustomStringConvertible {
  public var description: String {
    encoded
  }
}
