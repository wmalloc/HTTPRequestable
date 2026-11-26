//
//  Quality.swift
//
//  Created by Waqar Malik on 5/18/24
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
#endif

/// "br;q=1.0, gzip;q=0.9, deflate;q=0.8"
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
/// let quality: Quality = try [
///   .init(item: "br", parameters: 1.0),
///   .init(item: "gzip", parameters: 0.9),
///   .init(item: "deflate", parameters: 0.8)
/// ]
/// print(quality.encoded) // "br;q=1.0,gzip;q=0.9,deflate;q=0.8"
/// ```
///
/// - SeeAlso: `Quality.Item`, `Quality.Parameter`
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
  /// let item = try Quality.Item(item: "gzip", parameters: 0.9)
  /// ```
  ///
  /// - SeeAlso: `Quality`, `Quality.Parameter`
  public struct Item: Codable, Hashable, Sendable {
    public let item: String
    public let parameters: Parameter

    /// Creates an item.
    ///
    /// - Parameters:
    ///   - item: The value, such as `gzip`, `en-US` or `text/html`. It must be a token or a media range.
    ///   - parameters: The q-value, or `nil` to leave it out.
    /// - Throws: ``HTTPFieldValueError/invalidItem`` when `item` is not a token or a media range.
    public init(item: String, parameters: Parameter = nil) throws {
      guard HTTPFieldValueSyntax.isItem(item) else {
        throw HTTPFieldValueError.invalidItem
      }
      self.item = item
      self.parameters = parameters
    }

    private enum CodingKeys: String, CodingKey {
      case item, parameters
    }

    /// Decodes an item, validating it like ``init(item:parameters:)``.
    ///
    /// - Throws: ``HTTPFieldValueError`` when the decoded item or q-value is invalid, or a decoding error.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      try self.init(item: container.decode(String.self, forKey: .item),
                    parameters: container.decode(Parameter.self, forKey: .parameters))
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
  public struct Parameter: Codable, Hashable, Sendable {
    // swiftlint:disable identifier_name
    public let q: Float?

    /// Creates a q-value.
    ///
    /// - Parameter q: The quality, from `0` (not acceptable) to `1` (most preferred), or `nil` to leave
    ///   it out. It is written with at most three decimals, rounded.
    /// - Throws: ``HTTPFieldValueError/invalidQuality`` when `q` is NaN or outside `0...1`.
    public init(q: Float? = nil) throws {
      if let q, !(0 ... 1).contains(q) {
        throw HTTPFieldValueError.invalidQuality
      }
      self.init(uncheckedQ: q)
    }

    /// Creates a q-value from a `Double`.
    ///
    /// - Parameter double: The quality, from `0` to `1`.
    /// - Throws: ``HTTPFieldValueError/invalidQuality`` when `double` is NaN or outside `0...1`.
    public init(double: Double) throws {
      try self.init(q: Float(double))
    }

    /// Creates a q-value the caller has already checked.
    init(uncheckedQ q: Float?) {
      self.q = q
    }

    private enum CodingKeys: String, CodingKey {
      case q
    }

    /// Decodes a q-value, validating it like ``init(q:)``.
    ///
    /// - Throws: ``HTTPFieldValueError/invalidQuality`` when the decoded value is outside `0...1`, or a
    ///   decoding error.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      try self.init(q: container.decodeIfPresent(Float.self, forKey: .q))
    }
    // swiftlint:enable identifier_name
  }

  /// The items as a field value, such as `br;q=1.0,gzip;q=0.9`.
  ///
  /// q-values are written with at most three decimals, rounded (RFC 9110 section 12.4.2).
  public var encoded: String {
    items.map(\.encoded).joined(separator: ",")
  }
}

extension Quality.Item {
  /// The item with its q-value, if it has one.
  var encoded: String {
    guard let qvalue = parameters.q.flatMap(HTTPFieldValueSyntax.qvalue) else {
      return item
    }
    return "\(item);q=\(qvalue)"
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
  /// Creates a q-value from a literal such as `0.9`.
  ///
  /// - Precondition: `value` is in `0...1`.
  public init(floatLiteral value: Float) {
    precondition((0 ... 1).contains(value), "A q-value must be between 0 and 1")
    self.init(uncheckedQ: value)
  }
}

extension Quality.Parameter: ExpressibleByNilLiteral {
  /// Creates a parameter without a q-value.
  public init(nilLiteral: ()) {
    self.init(uncheckedQ: nil)
  }
}

extension Quality.Parameter: ExpressibleByStringLiteral {
  /// Creates a q-value from a literal such as `"0.9"`.
  ///
  /// - Precondition: `value` is a number in `0...1`.
  public init(stringLiteral value: String) {
    guard let quality = Float(value), (0 ... 1).contains(quality) else {
      preconditionFailure("A q-value must be a number between 0 and 1")
    }
    self.init(uncheckedQ: quality)
  }
}

extension Quality: CustomStringConvertible {
  public var description: String {
    encoded
  }
}
