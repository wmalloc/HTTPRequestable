//
//  KeyedItem.swift
//
//
//  Created by Waqar Malik on 5/18/24
//

import Foundation

/// A structure that wraps an item with a set of associated key-value string parameters.
///
/// `KeyedItem` provides a convenient way to associate additional metadata (as a dictionary of `String` keys and values)
/// with any item conforming to `Codable`, `Equatable`, and `Sendable`. The structure also supports collection-like
/// access to its parameters and custom string descriptions.
///
/// - Note: The structure is frozen, which means future versions will not add stored properties, ensuring binary compatibility.
///
/// - Parameters:
///   - ItemType: The type of the item to associate parameters with. Must conform to `Codable`, `Equatable`, and `Sendable`.
///
/// # Example
/// ```swift
/// let item = KeyedItem(item: 42, parameters: ["unit": "kg", "precision": "2"])
/// print(item["unit"]) // Optional("kg")
/// print(item.encoded) // "42; unit=kg; precision=2"
/// ```
///
/// # Collection Conformance
/// `KeyedItem` conforms to `Collection`, enabling iteration over its parameters.
///
/// # Thread Safety
/// `KeyedItem` is `Sendable` as long as its `ItemType` is `Sendable`, making it safe for use in concurrent contexts.
@frozen
public struct KeyedItem<ItemType: Codable & Equatable & Sendable>: Equatable, Sendable {
  public let item: ItemType
  public var parameters: [String: String]

  public init(item: ItemType, parameters: [String: String]) {
    self.item = item
    self.parameters = parameters
  }

  public subscript(key: String) -> String? {
    get { parameters[key] }
    set { parameters[key] = newValue }
  }

  public var encoded: String {
    "\(item); " + parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
  }
}

extension KeyedItem: Collection {
  public var startIndex: Dictionary<String, String>.Index {
    parameters.startIndex
  }

  public var endIndex: Dictionary<String, String>.Index {
    parameters.endIndex
  }

  public func index(after index: Dictionary<String, String>.Index) -> Dictionary<String, String>.Index {
    parameters.index(after: index)
  }

  public subscript(position: Dictionary<String, String>.Index) -> Dictionary<String, String>.Element {
    parameters[position]
  }
}

extension KeyedItem: CustomStringConvertible {
  public var description: String {
    encoded
  }
}
