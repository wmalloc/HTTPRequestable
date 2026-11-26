//
//  KeyedItem.swift
//
//  Created by Waqar Malik on 5/18/24
//

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
#endif

/// A structure that wraps an item with a set of associated key-value string parameters.
///
/// `KeyedItem` provides a convenient way to associate additional metadata (as a dictionary of `String` keys and values)
/// with any item conforming to `Codable`, `Equatable`, and `Sendable`. The structure also supports collection-like
/// access to its parameters and custom string descriptions.
///
/// - Parameters:
///   - ItemType: The type of the item to associate parameters with. Must conform to `Codable`, `Equatable`, and `Sendable`.
///
/// # Example
/// ```swift
/// let item = try KeyedItem(item: 42, parameters: ["unit": "kg", "precision": "2"])
/// print(item["unit"]) // Optional("kg")
/// print(item.encoded) // "42; precision=2; unit=kg"
/// ```
///
/// # Collection Conformance
/// `KeyedItem` conforms to `Collection`, enabling iteration over its parameters.
///
/// # Thread Safety
/// `KeyedItem` is `Sendable` as long as its `ItemType` is `Sendable`, making it safe for use in concurrent contexts.
public struct KeyedItem<ItemType: Codable & Equatable & Sendable>: Equatable, Sendable {
  public let item: ItemType
  /// The parameters. Change them with ``setParameter(_:forKey:)``, which validates them.
  public private(set) var parameters: [String: String]

  /// Creates an item with parameters, such as a `Content-Type` or `Content-Disposition` value.
  ///
  /// - Parameters:
  ///   - item: The item, such as `multipart/form-data`. Written with `"\(item)"`, it must be a token or a
  ///     media range.
  ///   - parameters: The parameters. Each key must be a token, and no value may contain a control
  ///     character such as CR or LF. Values that are not tokens are quoted when encoded.
  /// - Throws: ``HTTPFieldValueError/invalidItem``, ``HTTPFieldValueError/invalidParameterName(_:)`` or
  ///   ``HTTPFieldValueError/invalidParameterValue(name:)``.
  public init(item: ItemType, parameters: [String: String] = [:]) throws {
    guard HTTPFieldValueSyntax.isItem("\(item)") else {
      throw HTTPFieldValueError.invalidItem
    }
    for (key, value) in parameters {
      try Self.validateParameter(value, forKey: key)
    }
    self.init(uncheckedItem: item, parameters: parameters)
  }

  /// Creates an item from values the caller has already checked.
  init(uncheckedItem item: ItemType, parameters: [String: String]) {
    self.item = item
    self.parameters = parameters
  }

  /// The value of the parameter `key`, or `nil` when it is not set.
  public subscript(key: String) -> String? {
    parameters[key]
  }

  /// Sets or removes the parameter `key`.
  ///
  /// - Parameters:
  ///   - value: The value, or `nil` to remove the parameter. It must not contain a control character.
  ///   - key: The parameter name, which must be a token.
  /// - Throws: ``HTTPFieldValueError/invalidParameterName(_:)`` or
  ///   ``HTTPFieldValueError/invalidParameterValue(name:)``. The parameters are unchanged when it throws.
  public mutating func setParameter(_ value: String?, forKey key: String) throws {
    guard let value else {
      parameters[key] = nil
      return
    }
    try Self.validateParameter(value, forKey: key)
    parameters[key] = value
  }

  private static func validateParameter(_ value: String, forKey key: String) throws {
    guard HTTPFieldValueSyntax.isToken(key) else {
      throw HTTPFieldValueError.invalidParameterName(key)
    }
    guard HTTPFieldValueSyntax.isParameterValue(value) else {
      throw HTTPFieldValueError.invalidParameterValue(name: key)
    }
  }

  /// The item followed by its parameters, as used in a field value: `item; key=value; key="a value"`.
  ///
  /// - Parameters are sorted by key, so the result is the same on every run.
  /// - A value is written as it is when it is a token or already a quoted-string, and quoted otherwise,
  ///   so a `;` or `"` in it cannot add parameters.
  /// - Without parameters, the result is the item alone.
  public var encoded: String {
    let encodedParameters = parameters
      .sorted { $0.key < $1.key }
      .map { key, value in "\(key)=\(HTTPFieldValueSyntax.parameterValue(value))" }
    return (["\(item)"] + encodedParameters).joined(separator: "; ")
  }
}

extension KeyedItem: Collection {
  public typealias Index = Dictionary<String, String>.Index
  public typealias Element = Dictionary<String, String>.Element

  public var startIndex: Index {
    parameters.startIndex
  }

  public var endIndex: Index {
    parameters.endIndex
  }

  public func index(after index: Index) -> Index {
    parameters.index(after: index)
  }

  public subscript(position: Index) -> Element {
    parameters[position]
  }
}

extension KeyedItem: CustomStringConvertible {
  public var description: String {
    encoded
  }
}
